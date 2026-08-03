# Step 6 — Line-by-line explanation

Covers **Step 6 — Expansion: env vars, $?, quote removal, word
splitting**, per `PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/structs.h` (one new type) -> `inc/minishell.h` (new declarations) ->
`src/env/env.c` (`env_get`, the one small building block from an existing
module) -> `src/expansion/expand_var.c` (stage A: expanding `$` inside one
fragment) -> `src/expansion/expand_split.c` (stage B: turning expanded
fragments into final `argv` words) -> `src/expansion/expansion.c` (the
driver, tying both stages to the AST) -> `src/shell/shell.c` (wiring).

---

## 0. What the subject actually requires here (checked first)

Re-read `en.subject.pdf` before writing anything. Two sentences define
this entire step:

> Handle environment variables ($ followed by a sequence of characters)
> which should expand to their values.
> Handle $? which should expand to the exit status of the most recently
> executed foreground pipeline.

Combined with the quoting rules from step 3 (single quotes block
*everything*; double quotes block everything *except* `$`), that's the
whole mandatory spec: two things to expand, two quote types that gate
whether expansion happens at all. Word splitting itself isn't named in
that sentence — but it's the unavoidable consequence of the "$ expands to
its value" rule once that value can contain whitespace, and this project's
own checklist (in `PROGRESS.md`, written before this step started) already
scoped it in under this step's title. "If in doubt, take bash as
reference" is what shaped every specific rule below.

`friend_minishell/src/expansion/` was read for a second opinion, in
particular `expand_variables.c` and `expand_exit_code.c`. Its design does
`$VAR` expansion in one pass, then searches the *already-expanded* string
for a literal `"$?"` substring in a **second** pass and does a textual
find-and-replace. That's fragile in a way worth naming: if any variable's
*value* happens to literally contain the two characters `$?`, that second
pass would wrongly rewrite them too, since by then there's no way to tell
"this `$?` was a real un-expanded exit-status token" from "this `$?`
happened to survive inside an already-expanded value." This project
handles `$?` in the *same* single left-to-right scan as `$VAR` — the
moment a `$` is seen, it's resolved to whichever it is right then, so
there's no expanded output for a stray substring search to get confused
by. This is a deliberate improvement, not a copy, over the reference
project's approach.

---

## 1. `inc/structs.h` — one new type

```c
typedef struct s_split
{
	char	*acc;
	int		touched;
	t_token	*out;
}	t_split;
```
This is the one piece of new state the splitting algorithm (stage B,
below) needs to carry between calls: `acc` is the string being built up
for the *current* output word, `touched` distinguishes "nothing has ever
been glued onto `acc`" from "something — even an empty string — was
deliberately glued," and `out` accumulates the finished words. It lives
here, in `structs.h`, rather than as a `typedef` inside `expand_split.c`
itself, because Norminette forbids `typedef` in `.c` files outright — this
surfaced as an actual error during development (`FORBIDDEN_TYPEDEF`), fixed
by moving it here, matching where every other struct in the project
already lives. It's not part of the shell's persistent state the way
`t_cmd`/`t_redir` are — it's purely an implementation detail of one
function's internals — but the project doesn't have a "private struct"
convention, so it goes where everything else goes.

---

## 2. `inc/minishell.h` — new declarations

```c
char	*env_get(t_env *env, const char *key);
```
Added to the existing `// env` block: a straightforward linked-list
lookup, the one thing `env.c` was missing to support expansion reading
variable values.

```c
// expansion
void	expand(t_shell *shell);
char	*expand_fragment(const char *value, t_shell *shell);
void	expand_fragments(t_token *word, t_shell *shell);
t_token	*split_word(t_token *word);
```
`expand` is the module's real public API (called once from `shell.c`).
`expand_fragment`, `expand_fragments`, and `split_word` are cross-file
internals (used between `expand_var.c`, `expand_split.c`, and
`expansion.c`), declared centrally per the project's existing convention.

---

## 3. `src/env/env.c` — `env_get`

```c
char	*env_get(t_env *env, const char *key)
{
	size_t	len;

	len = ft_strlen(key);
	while (env)
	{
		if (env->key && ft_strncmp(env->key, key, len + 1) == 0)
			return (env->value);
		env = env->next;
	}
	return (NULL);
}
```
A linear walk, same shape as every other list-walk in the codebase. The
`len + 1` in the `ft_strncmp` call is what makes this an *exact* match
rather than a prefix match: libft has no `ft_strcmp` (consistent with the
standard, minimal 42 libft), so comparing `len(key) + 1` bytes means the
comparison includes each string's terminating `'\0'` — if `env->key` is
longer than `key` (e.g. looking up `"US"` against a stored `"USER"`), the
byte at position `len(key)` is `'\0'` on one side and `'S'` on the other,
which correctly fails the match instead of falsely succeeding on a prefix.
`env->key &&` guards the one legitimate way `env->key` can be `NULL` —
step 1's handling of a malformed `envp` entry with no `=` at all.
Returning `NULL` covers two cases identically on purpose: "no variable
with this name exists" and "it exists but its value is `NULL`" (the same
malformed-entry case) — both mean "expands to nothing" to a caller, so
there's no reason to distinguish them.

---

## 4. `src/expansion/expand_var.c` — stage A: expanding one fragment

```c
static int	is_var_start(char c)
{
	return (ft_isalpha(c) || c == '_');
}

static int	is_var_char(char c)
{
	return (ft_isalnum(c) || c == '_');
}
```
Standard shell identifier rules: a variable name must *start* with a
letter or underscore, but can *continue* with letters, digits, or
underscores. This distinction matters — see below for why `$` followed by
a digit is deliberately treated as *not* a variable at all (Decision #9).

```c
static char	*dollar_replacement(const char *s, int *i, t_shell *shell)
{
	int		start;
	char	*name;
	char	*value;

	if (s[*i + 1] == '?')
	{
		*i += 2;
		return (ft_itoa(shell->exit_status));
	}
	if (!is_var_start(s[*i + 1]))
	{
		(*i)++;
		return (ft_strdup("$"));
	}
	*i += 1;
	start = *i;
	while (is_var_char(s[*i]))
		(*i)++;
	name = ft_substr(s, start, *i - start);
	value = env_get(shell->env, name);
	free(name);
	if (!value)
		return (ft_strdup(""));
	return (ft_strdup(value));
}
```
Called with `s[*i]` known to be `'$'`. Three cases, checked in order:
- **`$?`**: the very next character is `?` — advance past both characters
  and return the exit status as a string (`ft_itoa`). This is the *only*
  place `$?` is handled anywhere in the codebase — no second pass, no
  string search, just a direct check at the exact position it's found.
- **Not a variable at all**: whatever follows `$` isn't `?` and isn't a
  valid identifier start. This covers a trailing lone `$` at the end of a
  fragment (reading `s[*i + 1]` here is always safe — a C string's `'\0'`
  guarantees a readable byte even at the very end, the same reasoning
  step 3's tokenizer already relied on for its own one-character
  lookahead), **and** it's also how Decisions #8 and #9 are enforced: `$$`
  (next char is `$`, not alpha/underscore/`?`) and `$1` (next char is a
  digit) both fall into this branch and come out as a literal `$`,
  un-expanded. Only the single `$` character is consumed here — whatever
  comes after it (a second `$`, a digit, anything) gets re-scanned by the
  caller on the next iteration as ordinary text (or another `$`).
- **A real variable**: scan forward while `is_var_char` holds (this is
  the *greedy* match that makes `x$UNSET_VARy` look up a variable literally
  named `UNSET_VARy`, not `UNSET_VAR` followed by literal `y` — this is
  exactly what real bash does too, verified against a live bash process,
  not a guess), look it up via `env_get`, and return its value — or an
  empty string if the variable doesn't exist, never `NULL` itself (nothing
  downstream needs to special-case "no value" versus "empty value").

```c
char	*expand_fragment(const char *value, t_shell *shell)
{
	char	*result;
	char	*piece;
	char	*joined;
	int		i;

	result = ft_strdup("");
	i = 0;
	while (value[i])
	{
		if (value[i] == '$')
			piece = dollar_replacement(value, &i, shell);
		else
		{
			piece = ft_substr(value, i, 1);
			i++;
		}
		joined = ft_strjoin(result, piece);
		free(result);
		free(piece);
		result = joined;
	}
	return (result);
}
```
One left-to-right scan of a single fragment's text: on a `$`, dispatch to
`dollar_replacement`; otherwise, copy one literal character through
unchanged. Every iteration produces one `piece`, glued onto the growing
`result`. This is quadratic in the length of the fragment (`ft_strjoin`
copies the whole accumulated string every time) — the same shape
`friend_minishell`'s own `expand_variables` uses — which is fine here
since a single shell-line fragment is never going to be long enough for
that to matter; optimizing it would be solving a problem this project
doesn't have.

```c
void	expand_fragments(t_token *word, t_shell *shell)
{
	char	*expanded;

	while (word)
	{
		if (!word->single_quoted)
		{
			expanded = expand_fragment(word->value, shell);
			free(word->value);
			word->value = expanded;
		}
		word = word->next;
	}
}
```
Walks one whole logical word (a `join_next` chain) and replaces every
non-single-quoted fragment's `value` with its expanded form, **in place**
— this is the "quote removal" and "`$` expansion except in single quotes"
half of the subject's rule, applied per-fragment exactly the way the
tokenizer already tagged each fragment's quoting back in step 3. A
single-quoted fragment is skipped entirely: its `value` was already
quote-stripped by the tokenizer and is never touched again — this *is*
the "single quotes prevent all metacharacter interpretation" rule, applied
by simply never calling `expand_fragment` on it.

---

## 5. `src/expansion/expand_split.c` — stage B: fragments to final words

This is the one genuinely intricate piece of this step, so it's worth
walking through the reasoning before the code. The question being
answered is: **given a chain of already-expanded fragments, some quoted
and some not, where do the final `argv`-word boundaries fall?**

The key fact that makes this tractable: real, literal whitespace typed
directly into the fragment's *original source text* can never appear here
at all — an unquoted space always ended a token back at tokenize time (a
new `t_token` starts after it), and a quoted space is part of a fragment's
literal text but was typed *inside* quotes. So the **only** way whitespace
ends up inside a fragment's *expanded* value is if that fragment is bare
(unquoted) and its `$VAR` expansion's value contains whitespace — exactly
the case real bash's word splitting is about. A **quoted** fragment
(single or double) never gets split, even if its expanded content
contains whitespace, because quoting is precisely what suppresses that —
this is true for double quotes even though `$` still expands inside them,
which is the entire point of the "expands but doesn't split" wording in
double-quote semantics.

```c
static void	finalize_word(t_split *sp)
{
	t_token	*tok;

	if (sp->touched)
	{
		tok = new_token(TOKEN_WORD, sp->acc);
		add_token_back(&sp->out, tok);
	}
	else
		free(sp->acc);
	sp->acc = ft_strdup("");
	sp->touched = 0;
}
```
Closes off whatever's been accumulated so far as one finished output word
— but only if `touched` is true. If nothing was ever glued (an unquoted
`$UNSET_VAR` on its own, expanding to nothing, glues nothing and never
sets `touched`), nothing is emitted at all — this is what makes `echo
$UNSET_VAR` produce **zero** arguments for that word, not an empty-string
one. Either way, `acc` is reset to a fresh empty string afterward so
accumulation can continue for whatever comes next.

```c
static void	glue(char *text, t_split *sp)
{
	char	*joined;

	joined = ft_strjoin(sp->acc, text);
	free(sp->acc);
	sp->acc = joined;
	sp->touched = 1;
}
```
Appends `text` onto the accumulator unconditionally and marks it
`touched` — used both for a whole quoted fragment's text (never split) and
for one whitespace-delimited chunk of a bare fragment's text (below).
Gluing an empty string still sets `touched = 1` — this is deliberately
what makes `echo ""` (a single quoted-but-empty fragment) still produce
**one** empty-string argument: quoting always counts as "something was
here," even if that something is nothing.

```c
static void	split_bare(char *text, t_split *sp)
{
	int		i;
	int		start;
	char	*chunk;

	i = 0;
	if (text[0] && (text[0] == ' ' || text[0] == '\t'))
		finalize_word(sp);
	while (text[i])
	{
		while (text[i] == ' ' || text[i] == '\t')
			i++;
		if (!text[i])
			break ;
		start = i;
		while (text[i] && text[i] != ' ' && text[i] != '\t')
			i++;
		chunk = ft_substr(text, start, i - start);
		glue(chunk, sp);
		free(chunk);
		if (text[i])
			finalize_word(sp);
	}
}
```
This is the piece that has to get bash's actual seam behavior right, so
it's worth tracing carefully:
- **Leading whitespace** (`text[0]` is a space/tab): whatever was
  accumulated *before* this fragment is immediately finalized — this
  matters when a bare fragment follows a quoted one with no gap (e.g.
  `"pre"$X` where `X` starts with a space): the quoted `"pre"` glued
  itself onto the accumulator and left it open (quoted text never
  self-finalizes — see `glue` above, called directly for quoted fragments
  in `split_word` below), so it's this leading-whitespace check, reached
  while processing the *next* fragment, that's actually responsible for
  closing off `"pre"` as its own word once it becomes clear something
  after it starts with a space.
- **The main loop**: skip a run of whitespace, capture the next
  non-whitespace run as `chunk`, glue it onto the accumulator (marking
  `touched`). Then — this is the crux — **only finalize immediately if
  `text[i]` is non-`'\0'` after capturing the chunk**, i.e. only if this
  chunk was followed by more whitespace (meaning it's fully bounded on
  both sides). If `text[i]` is `'\0'`, this chunk was the *last* one in
  the fragment with nothing after it — it stays open in the accumulator,
  ready to glue with whatever the *next* fragment in the chain
  contributes. This is exactly the mechanism that makes `"$X"$Y` (`X="a
  b"`, `Y="c d"`) come out as `a bc` and `d`, not three separate words:
  `"a b"` glues and stays open; `$Y` expands to `"c d"`, whose first chunk
  `"c"` glues onto the open accumulator (making `"a bc"`) and *is*
  finalized (because whitespace follows it inside `$Y`'s own value); `"d"`
  glues onto a fresh accumulator and stays open, to be finalized once
  there's nothing left in the whole word.

```c
t_token	*split_word(t_token *word)
{
	t_split	sp;

	sp.acc = ft_strdup("");
	sp.touched = 0;
	sp.out = NULL;
	while (word)
	{
		if (word->single_quoted || word->double_quoted)
			glue(word->value, &sp);
		else
			split_bare(word->value, &sp);
		word = word->next;
	}
	finalize_word(&sp);
	free(sp.acc);
	return (sp.out);
}
```
The driver for one logical word: any quoted fragment glues its whole
value in one shot (never split, regardless of content); any bare fragment
goes through `split_bare`. After every fragment in the chain has been
processed, whatever's left open in the accumulator is finalized as the
last word. The final `free(sp.acc)` cleans up the fresh empty string
`finalize_word` always leaves behind after its last call — never used
again, but still heap memory that needs releasing.

---

## 6. `src/expansion/expansion.c` — the driver, tying it to the AST

```c
static char	*join_word(t_token *word)
{
	char	*acc;
	char	*joined;

	acc = ft_strdup("");
	while (word)
	{
		joined = ft_strjoin(acc, word->value);
		free(acc);
		acc = joined;
		word = word->next;
	}
	return (acc);
}
```
The redirection-target equivalent of `split_word` — but per Decision #10,
deliberately *not* splitting: every fragment's (already stage-A-expanded)
text is concatenated in order, quoted or not, into exactly one final
string. No `t_split`/`touched` bookkeeping is needed here at all, since
there's no splitting decision to make.

```c
static void	expand_cmd_args(t_cmd *cmd, t_shell *shell)
{
	t_token	*old;
	t_token	*word;
	t_token	*new_args;

	old = cmd->args;
	new_args = NULL;
	while (old)
	{
		word = take_word(&old);
		expand_fragments(word, shell);
		add_token_back(&new_args, split_word(word));
		free_tokens(word);
	}
	cmd->args = new_args;
}
```
`cmd->args` going in is a flat chain of however many logical words came
from `parser.c`, back-to-back. This reuses `take_word()` — the *exact*
same function `parser.c` uses to detach one word at a time while building
the AST — to peel words off the front one at a time here too: expand the
word's fragments (stage A), split it into however many final words result
(stage B), append those to the new list, then free the now-fully-consumed
original word chain (its values have already been read, either copied
whole via `glue` or copied piecewise via `split_bare`'s `ft_substr` calls —
nothing in the new list points back into it). Once `old` is empty,
`cmd->args` is swapped for the freshly built `new_args`.

```c
static void	expand_cmd_redirs(t_cmd *cmd, t_shell *shell)
{
	t_redir	*redir;
	char	*joined;

	redir = cmd->redirs;
	while (redir)
	{
		expand_fragments(redir->target, shell);
		joined = join_word(redir->target);
		free_tokens(redir->target);
		redir->target = new_token(TOKEN_WORD, joined);
		redir = redir->next;
	}
}
```
Same stage-A expansion, but each redirection's target then goes through
`join_word` instead of `split_word` — one result, always. The old fragment
chain is freed and `target` is replaced with a single-node `t_token`
holding the final string — `t_redir`'s field type doesn't need to change
at all for this, since a `t_token` chain of length one is still a
perfectly valid `t_token *`.

```c
void	expand(t_shell *shell)
{
	t_cmd	*cmd;

	cmd = shell->ast;
	while (cmd)
	{
		expand_cmd_args(cmd, shell);
		expand_cmd_redirs(cmd, shell);
		cmd = cmd->next;
	}
}
```
The module's public entry point: walk every command in the pipeline,
expanding its args and its redirections' targets. Order between the two
doesn't matter — they're independent parts of the same `t_cmd`.

---

## 7. `src/shell/shell.c` — wiring it in

```c
else if (shell->tokens)
{
	shell->ast = parse(&shell->tokens);
	if (shell->ast)
		expand(shell);
	debug_print_ast(shell->ast);
	free_cmd(shell->ast);
	shell->ast = NULL;
}
```
One line added (`if (shell->ast) expand(shell);`) between parsing and the
still-temporary `debug_print_ast`. `expand` mutates `cmd->args`/
`redir->target` on the existing `shell->ast` in place — nothing new to
free or reassign at this level, since `expand_cmd_args`/
`expand_cmd_redirs` already handle their own old-list cleanup internally.
The guard against `shell->ast` being `NULL` covers step 5's own edge case
(a `malloc` failure inside `parse()`) — expansion has nothing to do if
there's no AST to expand.

`debug_print_ast` itself needed no changes: it already prints whatever's
in `cmd->args`/`redir->target` regardless of what stage produced it, so
running it after `expand()` now shows the *final*, post-expansion argv
values (though every field's quote/`join_next` flags print as `0` now,
since the new `t_token` nodes `split_word`/`join_word` produce are plain
final strings with no quoting information left to carry — there's nothing
downstream that needs it anymore).

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `process_line`
-> `tokenize` (step 3) -> `validate_tokens` (step 4) -> `parse` (step 5)
-> `expand` (-> `expand_cmd_args` -> `take_word` / `expand_fragments`
(-> `expand_fragment` -> `dollar_replacement` -> `env_get`) / `split_word`
(-> `glue` / `split_bare` / `finalize_word`); `expand_cmd_redirs` ->
`expand_fragments` / `join_word`) -> `debug_print_ast` -> `free_cmd` ->
loop back to `readline`.

Verified by piping identical input through this project's binary and a
real `bash` process side by side (see `PROGRESS.md` for the exact test
list) — every `argv`-level word boundary matched, including the
seam-gluing case (`"$X"$Y` -> two words, not three) that's the one piece
of real bash-specific behavior in this whole step. `valgrind
--leak-check=full`: 0 definitely/indirectly/possibly lost bytes.

Nothing is executed yet — that starts at **Step 7 (execution engine)** per
`PROGRESS.md`.

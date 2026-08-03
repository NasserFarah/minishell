# Step 3 — Line-by-line explanation

Covers **Step 3 — Tokenizer**, per `PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/structs.h` (new types) -> `inc/minishell.h` (new declarations) ->
`src/tokenizer/tokenizer_utils.c` (list plumbing) ->
`src/tokenizer/tokenizer_word.c` (the interesting part: words + quotes) ->
`src/tokenizer/tokenizer.c` (the driver) -> `src/shell/shell.c` (wiring +
temporary debug print).

---

## 0. What the subject actually requires here (checked first)

Before writing anything, `en.subject.pdf` was re-read for exactly what this
step is allowed/required to cover:

- Redirections: `<`, `>`, `<<` (with a delimiter), `>>`.
- Pipes: `|`.
- `'...'` prevents *all* metacharacter interpretation inside it.
- `"..."` prevents metacharacter interpretation *except* `$`.
- **Must not** interpret unclosed quotes, or characters not asked for such
  as `\` or `;`.
- "Anything not asked is not required" — so no `&&`/`||`/parentheses
  (bonus, step 9) and no wildcard-specific token (bonus, step 10) yet.

That directly shaped the token type list below: exactly six variants, no
more.

---

## 1. `inc/structs.h` — the new types

```c
typedef enum e_token_type
{
	TOKEN_WORD,
	TOKEN_PIPE,
	TOKEN_REDIR_IN,
	TOKEN_REDIR_OUT,
	TOKEN_REDIR_APPEND,
	TOKEN_HEREDOC
}	t_token_type;
```
One variant per thing the *mandatory* subject text mentions: a word, `|`,
`<`, `>`, `>>`, `<<`. Nothing bonus-scoped is here yet — adding `TOKEN_AND`/
`TOKEN_OR`/`TOKEN_WILDCARD` now would be building ahead of the checklist for
features not being implemented for several more steps.

```c
typedef struct s_token
{
	t_token_type	type;
	char			*value;
	int				single_quoted;
	int				double_quoted;
	int				join_next;
	struct s_token	*next;
}	t_token;
```
- `type` — which of the six kinds this node is.
- `value` — heap-allocated text, quotes already stripped. `NULL` for
  operator tokens (`|`, `<`, `>`, `>>`, `<<`) — the type alone fully
  describes them, no text needed.
- `single_quoted` / `double_quoted` — booleans, meaningful only for
  `TOKEN_WORD`: which quote type (if any) produced *this specific node's*
  text. Both `0` means the text was bare/unquoted.
- `join_next` — `1` if this node is glued to the *next* node with no
  unquoted whitespace between them, i.e. they're both fragments of the same
  shell "word" and must be concatenated back together once each fragment
  has been through expansion (later step). `0` means this node is the last
  fragment of its word.
- `next` — list link, same self-referential-`struct` pattern as `t_env`
  (the `struct s_token *` here, not `t_token *`, for the same reason
  `t_env` uses `struct s_env *`: the typedef name doesn't exist yet at this
  point inside its own definition).

**Why one word can be several `t_token` nodes** — this is the one real
design decision in this step, so it's worth an example. Take:

```
echo "Hello, "$USER'!'
```

In bash this is *one* argument to `echo`, built from three differently
quoted fragments glued together: a double-quoted piece, a bare piece (which
still needs `$USER` expanded later), and a single-quoted piece. If the
tokenizer flattened all three into one `t_token` with one pair of booleans,
that per-fragment information would be gone — there would be no way for
the expansion step to know "expand `$` in the middle third only, leave the
first and last thirds alone." So instead, tokenizing this word produces
**three linked nodes**:

```
[WORD] value="Hello, "  double_quoted=1  join_next=1
[WORD] value="$USER"    (bare)           join_next=1
[WORD] value="!"        single_quoted=1  join_next=0
```

Step 6 (expansion) will later expand each node according to its own flags,
then splice every run of `join_next`-connected nodes back into a single
final string before it becomes one `argv` entry. That splicing isn't
implemented yet — this step only needs to produce the correctly-flagged
fragments.

```c
typedef struct s_shell
{
	t_env	*env;
	int		exit_status;
	int		interactive;
	t_token	*tokens;
}	t_shell;
```
One field added: `tokens`, the head of the list `tokenize()` builds for the
line currently being processed.

---

## 2. `inc/minishell.h` — new declarations

```c
// tokenizer
t_token	*tokenize(const char *line);
t_token	*new_token(t_token_type type, char *value);
t_token	*make_word_token(const char *line, int *i, int *error);
void	add_token_back(t_token **head, t_token *new);
void	free_tokens(t_token *tokens);
int		is_operator_char(char c);
```
Same convention as the existing `// env` / `// shell` / `// signals`
blocks: every function callable from another `.c` file gets declared here,
grouped by the file it lives in conceptually. `new_token`, `add_token_back`,
`make_word_token`, and `is_operator_char` are only ever called from the
other two tokenizer files, not from `main.c`/`shell.c` — they're declared
centrally here anyway because this project doesn't (yet) use per-module
private headers, matching how the rest of the codebase is organized so
far. Only `tokenize` and `free_tokens` are the module's real public API.

---

## 3. `src/tokenizer/tokenizer_utils.c` — list plumbing

```c
t_token	*new_token(t_token_type type, char *value)
{
	t_token	*token;

	token = malloc(sizeof(t_token));
	if (!token)
		return (NULL);
	token->type = type;
	token->value = value;
	token->single_quoted = 0;
	token->double_quoted = 0;
	token->join_next = 0;
	token->next = NULL;
	return (token);
}
```
A constructor, same shape as `env.c`'s `new_env_node`: takes ownership of
whatever `value` pointer it's handed (doesn't `strdup` it — the caller
already allocated it), zero-initializes the flag fields so every caller
only has to set the ones that actually apply to it, and propagates a
`malloc` failure as `NULL` rather than crashing.

```c
void	add_token_back(t_token **head, t_token *new)
{
	t_token	*last;

	if (!*head)
	{
		*head = new;
		return ;
	}
	last = *head;
	while (last->next)
		last = last->next;
	last->next = new;
}
```
Identical in shape to `env.c`'s `env_add_back`, and works for a subtlety
this step relies on: `new` here is sometimes not a single node but the
*head of an already-linked chain* (see `make_word_token` below, which
returns several nodes pre-linked via their own `->next` pointers for one
word). Appending just the chain's head to the tail of the main list is
enough — the rest of the chain rides along for free, since it's already
linked.

```c
void	free_tokens(t_token *tokens)
{
	t_token	*next;

	while (tokens)
	{
		next = tokens->next;
		free(tokens->value);
		free(tokens);
		tokens = next;
	}
}
```
Same teardown pattern as `free_env`: save `next` before freeing the current
node (freeing first would make reading `tokens->next` a use-after-free).
`free(NULL)` is a defined no-op, so this is safe even for operator tokens
whose `value` is `NULL`.

---

## 4. `src/tokenizer/tokenizer_word.c` — words and quotes

This file's whole job is: starting at some non-whitespace, non-operator
character, consume exactly one shell "word" and return it as a chain of
one or more `t_token` nodes.

```c
static int	segment_continues(const char *line, int i)
{
	if (!line[i])
		return (0);
	if (line[i] == ' ' || line[i] == '\t')
		return (0);
	if (is_operator_char(line[i]))
		return (0);
	return (1);
}
```
One predicate, used for two different questions that happen to have the
same answer: "should the outer word-loop keep going?" and "is the fragment
I just finished glued to another fragment right after it (no gap)?" Both
are really the same question — "is there more of this word here?" — so one
function serves both call sites in `make_word_token` below.

```c
static t_token	*parse_quoted_segment(const char *line, int *i, int *error)
{
	char	quote;
	int		start;
	t_token	*token;

	quote = line[*i];
	(*i)++;
	start = *i;
	while (line[*i] && line[*i] != quote)
		(*i)++;
	if (!line[*i])
	{
		write(STDERR_FILENO, "minishell: unclosed quote\n", 26);
		*error = 1;
		return (NULL);
	}
	token = new_token(TOKEN_WORD, ft_substr(line, start, *i - start));
	(*i)++;
	if (token && quote == '\'')
		token->single_quoted = 1;
	else if (token)
		token->double_quoted = 1;
	return (token);
}
```
- `quote = line[*i]` remembers *which* quote character opened this run
  (`'` or `"`), then `(*i)++` steps past it.
- The scan loop looks only for that *same* character — a `"` inside a
  `'...'` run (or vice versa) is just an ordinary character, never treated
  as closing anything. This is exactly the subject's rule that each quote
  type "prevents interpretation" of everything else while it's open,
  including the other quote character and every operator character.
- Reaching end-of-string (`!line[*i]`) before finding the matching quote is
  the unclosed-quote case the subject explicitly says must not be silently
  accepted: `write` an error directly (async-signal-safe raw syscall, same
  reasoning as the signal handler in step 2 — though not strictly required
  here, it's consistent with the rest of the codebase), set `*error`, and
  return `NULL` without advancing `*i` further.
- On success, `ft_substr(line, start, *i - start)` copies out exactly the
  text *between* the quotes (quotes themselves excluded — this is the
  "quote removal" the subject calls for), `(*i)++` steps past the closing
  quote, and the matching boolean flag is set depending on which quote
  character it was. Note: even an empty run (`''` or `""`) still produces a
  token whose `value` is `""` (an empty but non-NULL string) — this matters
  because `echo ''` must still pass one empty argument to `echo`, not zero
  arguments.

```c
static t_token	*parse_bare_segment(const char *line, int *i)
{
	int	start;

	start = *i;
	while (segment_continues(line, *i) && line[*i] != '\''
		&& line[*i] != '"')
		(*i)++;
	return (new_token(TOKEN_WORD, ft_substr(line, start, *i - start)));
}
```
The unquoted case: consume characters until whitespace, an operator
character, end of string, *or* a quote character starts a new differently
quoted fragment of the same word (e.g. the `$USER` in the running example —
bare text that stops the instant the following `'` opens a new fragment).
Both flags stay `0` (bare), matching `new_token`'s zero-initialization.

```c
t_token	*make_word_token(const char *line, int *i, int *error)
{
	t_token	*head;
	t_token	*seg;

	head = NULL;
	while (segment_continues(line, *i))
	{
		if (line[*i] == '\'' || line[*i] == '"')
			seg = parse_quoted_segment(line, i, error);
		else
			seg = parse_bare_segment(line, i);
		if (!seg)
		{
			free_tokens(head);
			return (NULL);
		}
		if (segment_continues(line, *i))
			seg->join_next = 1;
		add_token_back(&head, seg);
	}
	return (head);
}
```
The loop that stitches fragments into one word's worth of `t_token`
chain: each iteration produces exactly one fragment (quoted or bare),
checks — *before* appending it — whether the character right after this
fragment continues the same word (no gap), and if so marks `join_next = 1`
on the fragment just produced. If a fragment fails (quote error or
allocation failure), everything built so far *for this word* is freed
right here — the caller (`tokenize`) never has to know how many fragments
a failed word had partially produced.

---

## 5. `src/tokenizer/tokenizer.c` — the driver

```c
int	is_operator_char(char c)
{
	return (c == '|' || c == '<' || c == '>');
}

static void	skip_spaces(const char *line, int *i)
{
	while (line[*i] == ' ' || line[*i] == '\t')
		(*i)++;
}
```
Two small predicates. `is_operator_char` is shared with
`tokenizer_word.c` (hence declared in the header, not `static` here) since
both files need the same definition of "a character that ends a word."

```c
static t_token	*make_operator_token(const char *line, int *i)
{
	if (line[*i] == '|')
	{
		(*i)++;
		return (new_token(TOKEN_PIPE, NULL));
	}
	if (line[*i] == '<')
	{
		if (line[*i + 1] == '<')
		{
			*i += 2;
			return (new_token(TOKEN_HEREDOC, NULL));
		}
		(*i)++;
		return (new_token(TOKEN_REDIR_IN, NULL));
	}
	if (line[*i + 1] == '>')
	{
		*i += 2;
		return (new_token(TOKEN_REDIR_APPEND, NULL));
	}
	(*i)++;
	return (new_token(TOKEN_REDIR_OUT, NULL));
}
```
Only called when `line[*i]` is already known to be `|`, `<`, or `>`
(checked by the caller). The one-character-of-lookahead pattern
(`line[*i + 1] == '<'` / `== '>'`) is what distinguishes `<` from `<<` and
`>` from `>>` — reading `line[*i + 1]` when `line[*i]` is a real character
is always safe here because a C string's `\0` terminator guarantees
there's always at least one more readable byte to compare against, even at
the very end of the line.

```c
static int	next_token(const char *line, int *i, t_token **head)
{
	t_token	*part;
	int		error;

	error = 0;
	if (is_operator_char(line[*i]))
		part = make_operator_token(line, i);
	else
		part = make_word_token(line, i, &error);
	if (!part)
		return (1);
	add_token_back(head, part);
	return (0);
}

t_token	*tokenize(const char *line)
{
	t_token	*head;
	int		i;

	head = NULL;
	i = 0;
	while (line[i])
	{
		skip_spaces(line, &i);
		if (!line[i])
			break ;
		if (next_token(line, &i, &head))
		{
			free_tokens(head);
			return (NULL);
		}
	}
	return (head);
}
```
`next_token` exists mainly to keep `tokenize` itself short (under
Norminette's 25-line limit) — it produces exactly one operator token or one
whole-word chain and appends it, returning `1` on any failure (quote error
*or* a plain allocation failure; both are treated identically: bail out).
`tokenize` itself is now just: skip gaps, stop at end of line, otherwise
grab the next token(s); on any failure, free everything accumulated *so
far* for the whole line and return `NULL` rather than handing back a
partially-built, silently-truncated token list. A blank line (or a line
that's only whitespace) naturally produces `head == NULL` with no error —
`shell_loop` treats that exactly like "nothing to do," same as bash.

---

## 6. `src/shell/shell.c` — wiring it in, and a temporary debug print

```c
shell->tokens = tokenize(line);
debug_print_tokens(shell->tokens);
free_tokens(shell->tokens);
shell->tokens = NULL;
```
This is the first step where the `shell` parameter `shell_loop` has always
accepted is actually used (the `(void)shell;` placeholder from step 1 is
gone). Since the parser doesn't exist yet, there's nothing to *do* with the
tokens beyond this step — so `debug_print_tokens` (a small static helper
also added to `shell.c`, printing each token's type and, for words, its
value/flags) exists purely to make the tokenizer's output visible while
testing interactively, the same way step 2 was verified by literally
watching Ctrl-C behavior in a live terminal. **This print is scaffolding,
not a feature** — step 5 (parser) will delete it and replace these four
lines with something like `shell->ast = parse(shell->tokens)`, at which
point the tokens stop being immediately freed and start flowing into the
next stage.

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `tokenize`
(-> `skip_spaces` / `next_token` -> `make_operator_token` or
`make_word_token` -> `parse_quoted_segment` / `parse_bare_segment` ->
`new_token` / `add_token_back`, repeated per token) -> `debug_print_tokens`
-> `free_tokens` -> loop back to `readline`.

Nothing is validated, parsed, or executed yet — that starts at **Step 4
(token validation / syntax errors)** per `PROGRESS.md`.

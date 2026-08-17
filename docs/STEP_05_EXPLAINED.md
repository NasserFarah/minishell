# Step 5 — Line-by-line explanation

Covers **Step 5 — Parser: build AST**, per `PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/structs.h` (new types) -> `inc/minishell.h` (new declarations) ->
`src/parser/parser_utils.c` (the plumbing three other functions lean on) ->
`src/parser/parser_redir.c` (turning a redirection operator into a node) ->
`src/parser/parser.c` (the driver: commands and pipes) ->
`src/shell/shell.c` + `src/shell/debug_pipeline.c` (wiring + temporary
visualization).

---

## 0. What the subject actually requires here (checked first)

Same situation as step 4: `en.subject.pdf` has no parser grammar written
down anywhere. What it *does* establish, across the whole mandatory
section, is exactly two structural features to represent:
- "Implement pipes (`|`). The output of each command in the pipeline is
  connected to the input of the next."
- Four redirections (`<`, `>`, `<<` with a delimiter, `>>`), each attached
  to whichever command it appears next to.

Nothing about `&&`, `||`, or `()` — those are the bonus part (step 9),
gated on the mandatory part being "fully implemented and functions without
any issues" first. That directly shapes the two decisions below.

`friend_minishell/inc/structs.h` was read again for a second opinion (as
the working agreement allows), specifically `t_node`/`t_cmd`/`t_redir`/
`t_arg`. Its `t_node` is a binary tree (`NODE_CMD`/`NODE_PIPE`/`NODE_AND`/
`NODE_OR`, `left`/`right` children) because its token enum already has
`TOKEN_AND`/`TOKEN_OR`/`TOKEN_LPAREN`/`TOKEN_RPAREN` — bonus features it
built from the start. This project's `t_token_type` deliberately doesn't
have those yet (step 3's own decision), so copying that tree shape now
would mean building infrastructure for tokens that literally cannot exist
in the stream yet.

---

## 1. `inc/structs.h` — the new types

```c
typedef enum e_redir_type
{
	REDIR_IN,
	REDIR_OUT,
	REDIR_APPEND,
	REDIR_HEREDOC
}	t_redir_type;

typedef struct s_redir
{
	t_redir_type	type;
	t_token			*target;
	struct s_redir	*next;
}	t_redir;
```
One variant per redirection kind, same four the tokenizer already
distinguishes (`TOKEN_REDIR_IN`/`_OUT`/`_APPEND`/`TOKEN_HEREDOC`) — this is
a deliberately separate enum from `t_token_type` rather than reusing it,
because a redirection's *meaning* in the AST (an action to perform) is a
different concept from a *token* (a piece of lexed input), even though
right now the two enums happen to line up one-to-one.

`target` is a `t_token *`, not a `char *` — this is Decision #7 in
`PROGRESS.md`, and the one real design choice worth dwelling on. A
redirection's filename (or heredoc delimiter) is, grammatically, just
another shell *word* — it can be built from multiple quote-fragments
exactly like an argument can (`> "$HOME"/out` is one target word made of a
double-quoted fragment and a bare fragment glued by `join_next`, same as
any argument). The tokenizer already has a type that represents "one word,
possibly several joined quote-fragments, each flagged with its own
quoting": `t_token` itself. Inventing a second, parallel type — a
`t_filename` with its own `value`/`single_quoted`/`double_quoted`/
`join_next`/`next` fields — would just be `t_token` with a different name.
So `target` reuses `t_token` directly: the parser detaches the right
sub-chain of the *existing* tokenizer output and hangs it here, unflattened
and unexpanded, ready for step 6.

```c
typedef struct s_cmd
{
	t_token			*args;
	t_redir			*redirs;
	struct s_cmd	*next;
}	t_cmd;
```
Same reasoning applies to `args`: it's the `t_token` fragment-chain for
every argument *word* of this command, back to back, in original order.
There's no `t_arg` type either, for the same reason there's no
`t_filename` — `args` is just "all the WORD tokens belonging to this
command," and the existing `join_next` flag already tells you exactly
where one word ends and the next begins, so nothing new is needed to
represent that boundary.

`next` makes `t_cmd` itself a singly-linked list — this is Decision #6:
the AST for the mandatory part is a **flat pipeline**, not a tree. A
pipeline like `a | b | c` is represented as three `t_cmd` nodes chained
together, nothing more. There's no `t_node`/`NODE_PIPE` wrapper, because a
tree only earns its complexity once there's real branching to represent —
which arrives with `&&`/`||`/`()` in step 9, not before. When that step
lands, the natural extension is a tree whose leaves are these same
`t_cmd`-chain pipelines and whose internal nodes are `AND`/`OR`/grouping —
that's a deliberate "revisit later," not a gap being papered over now.

```c
typedef struct s_shell
{
	t_env	*env;
	int		exit_status;
	int		interactive;
	t_token	*tokens;
	t_cmd	*pipeline;
}	t_shell;
```
One field added: `pipeline`, the head of the pipeline `parse()` builds for the
line currently being processed — same lifecycle as `tokens` already had
(set at the start of processing a line, freed and reset to `NULL` by the
end of that same iteration; nothing persists across `readline()` calls).

---

## 2. `inc/minishell.h` — new declarations

```c
// parser
t_cmd	*parse(t_token **tokens);
t_cmd	*new_cmd(void);
t_token	*take_word(t_token **tokens);
int		consume_redir(t_token **tokens, t_redir **redirs);
void	free_cmd(t_cmd *cmd);

// shell (debug scaffolding, temporary — removed once execution lands)
void	debug_print_pipeline(t_cmd *pipeline);
```
Same convention as every step so far: everything callable from another
`.c` file is declared here. Only `parse` and `free_cmd` are the module's
real public API (called from `shell.c`); `new_cmd`, `take_word`, and
`consume_redir` are internal to the three parser files but still declared
centrally, matching the project's existing style (no per-module private
headers yet). `debug_print_pipeline` is explicitly commented as temporary in
the header itself, the same way step 3's `debug_print_tokens` was flagged
in `PROGRESS.md` (though that one, being `static`, never needed a header
entry at all — this one does, since it now lives in its own file).

---

## 3. `src/parser/parser_utils.c` — the shared plumbing

```c
t_cmd	*new_cmd(void)
{
	t_cmd	*cmd;

	cmd = malloc(sizeof(t_cmd));
	if (!cmd)
		return (NULL);
	cmd->args = NULL;
	cmd->redirs = NULL;
	cmd->next = NULL;
	return (cmd);
}
```
A constructor, same shape as every other `new_*` function in the codebase
(`new_token`, `new_env_node`): zero-initializes every field, propagates a
`malloc` failure as `NULL`.

```c
t_token	*take_word(t_token **tokens)
{
	t_token	*head;
	t_token	*cur;

	head = *tokens;
	cur = head;
	while (cur->join_next)
		cur = cur->next;
	*tokens = cur->next;
	cur->next = NULL;
	return (head);
}
```
The one function every other piece of the parser leans on. Given `*tokens`
currently pointing at the *start* of a word (a `TOKEN_WORD` node), this
walks forward through however many `join_next`-chained fragments make up
that one word, stopping at the fragment whose `join_next` is `0` (the
word's last piece). Then, in this exact order:
1. `*tokens = cur->next` — save where the rest of the flat list continues
   *before* touching anything, since the next line is about to overwrite
   what `cur->next` currently holds.
2. `cur->next = NULL` — cut the extracted chain loose from the old list.

The result: `head` is now a fully self-contained, correctly-terminated
chain representing exactly one word (whether that's one fragment or five),
and `*tokens` has been advanced past all of it. This works identically
whether it's called for a command argument or a redirection target — both
are "detach one word from the front of the list," full stop.

```c
static void	free_redirs(t_redir *redirs)
{
	t_redir	*next;

	while (redirs)
	{
		next = redirs->next;
		free_tokens(redirs->target);
		free(redirs);
		redirs = next;
	}
}

void	free_cmd(t_cmd *cmd)
{
	t_cmd	*next;

	while (cmd)
	{
		next = cmd->next;
		free_tokens(cmd->args);
		free_redirs(cmd->redirs);
		free(cmd);
		cmd = next;
	}
}
```
Same "save `next` before freeing, so freeing the current node can't turn
into a use-after-free on the next iteration" pattern as `free_tokens` and
`free_env` before it. `free_cmd`, despite its singular name, frees the
*whole* pipeline list — matching the existing convention: `free_tokens`
already frees a whole token chain, not "one token," so `free_cmd` freeing
a whole command chain is consistent, not a new pattern. Both `args` and
each redir's `target` are freed with the *existing* `free_tokens()` — no
new teardown logic needed, since they're both just `t_token` chains.

---

## 4. `src/parser/parser_redir.c` — one redirection operator, consumed

```c
static t_redir_type	redir_type(t_token_type type)
{
	if (type == TOKEN_REDIR_IN)
		return (REDIR_IN);
	if (type == TOKEN_REDIR_OUT)
		return (REDIR_OUT);
	if (type == TOKEN_REDIR_APPEND)
		return (REDIR_APPEND);
	return (REDIR_HEREDOC);
}
```
A direct mapping, token type to AST redir type. Only ever called on a
token already known to be one of the four redirection types (checked by
the caller), so the unconditional final `return` is safe, not a silent
wrong-answer fallback.

```c
static void	append_redir(t_redir **redirs, t_redir *new)
{
	t_redir	*last;

	if (!*redirs)
	{
		*redirs = new;
		return ;
	}
	last = *redirs;
	while (last->next)
		last = last->next;
	last->next = new;
}
```
Identical shape to every other `add_*_back` in the codebase
(`add_token_back`, `env_add_back`) — the same list-append pattern, just
for `t_redir` this time.

```c
int	consume_redir(t_token **tokens, t_redir **redirs)
{
	t_redir	*redir;
	t_token	*op;

	op = *tokens;
	redir = malloc(sizeof(t_redir));
	if (!redir)
		return (0);
	redir->type = redir_type(op->type);
	*tokens = op->next;
	free(op);
	redir->target = take_word(tokens);
	redir->next = NULL;
	append_redir(redirs, redir);
	return (1);
}
```
Called with `*tokens` sitting exactly on the redirection operator token
(`<`, `>`, `>>`, or `<<`). Order matters here:
1. `redir = malloc(...)` is attempted **first**, before anything is
   consumed. If it fails, `*tokens` is returned completely untouched — the
   caller's cleanup path (see `parse_command` below) can safely
   `free_tokens(*tokens)` on the *original*, still-intact remainder,
   nothing has been partially detached or leaked.
2. Only once the allocation succeeds does the operator token `op` actually
   get consumed: `*tokens = op->next` steps past it, `free(op)` discards
   it (an operator token carries no `value` and no further meaning once
   its type has been read into `redir->type`).
3. `take_word(tokens)` then detaches the target word — guaranteed by step
   4's `validate_redirs` to exist and be a `TOKEN_WORD` — exactly the same
   way an argument word would be detached.

No grammar checking happens in this function at all: step 4 already
guarantees a redirection operator here is followed by a valid `TOKEN_WORD`
target, so the only thing left that could actually fail is the `malloc`.

---

## 5. `src/parser/parser.c` — the driver: commands and pipes

```c
static void	skip_pipe(t_token **tokens)
{
	t_token	*pipe;

	pipe = *tokens;
	*tokens = pipe->next;
	free(pipe);
}
```
A `TOKEN_PIPE` node carries no value either — once its presence has told
the driver "start a new command here," the node itself is discarded the
same way an operator token is in `consume_redir`.

```c
static int	parse_token(t_token **tokens, t_cmd *cmd)
{
	if ((*tokens)->type == TOKEN_WORD)
	{
		add_token_back(&cmd->args, take_word(tokens));
		return (1);
	}
	return (consume_redir(tokens, &cmd->redirs));
}
```
Handles exactly one token's worth of work for the command currently being
built: a `TOKEN_WORD` gets detached as a whole word (`take_word`) and
appended to `cmd->args` — reusing `add_token_back` from step 3 unchanged,
which already knows how to append a multi-node chain, not just a single
node, to the tail of a list. Anything else at this point (guaranteed by
step 4 to be one of the four redirection types — a `TOKEN_PIPE` would have
already stopped the caller's loop before reaching here) is handed to
`consume_redir`. The return value is a simple success flag, propagated
straight from `consume_redir` when that's the branch taken.

```c
static t_cmd	*parse_command(t_token **tokens)
{
	t_cmd	*cmd;
	int		ok;

	cmd = new_cmd();
	if (!cmd)
	{
		free_tokens(*tokens);
		*tokens = NULL;
		return (NULL);
	}
	ok = 1;
	while (ok && *tokens && (*tokens)->type != TOKEN_PIPE)
		ok = parse_token(tokens, cmd);
	if (!ok)
	{
		free_tokens(*tokens);
		*tokens = NULL;
		free_cmd(cmd);
		return (NULL);
	}
	return (cmd);
}
```
Builds one command: create it, then keep handing tokens to `parse_token`
until either a pipe is reached, the input runs out, or something fails.
The **invariant this function establishes and every caller relies on**:
*a `NULL` return always means `*tokens` has already been fully freed and
set to `NULL`* — both failure paths (the initial `malloc`, and a failure
partway through the loop) free whatever remains of `*tokens` themselves
before returning. This means nobody further up the call chain ever has to
ask "did this failure already clean up the tokens, or do I still need to?"
— the answer is always "already handled." This single rule is what keeps
`parse()` below simple.

```c
t_cmd	*parse(t_token **tokens)
{
	t_cmd	*head;
	t_cmd	*cur;

	head = parse_command(tokens);
	if (!head)
		return (NULL);
	cur = head;
	while (*tokens)
	{
		skip_pipe(tokens);
		cur->next = parse_command(tokens);
		if (!cur->next)
		{
			free_cmd(head);
			return (NULL);
		}
		cur = cur->next;
	}
	return (head);
}
```
Parse one command, then, for as long as tokens remain, consume a pipe and
parse the next command, linking it onto the tail. Note what's *not* here:
no check that `(*tokens)->type == TOKEN_PIPE` before calling `skip_pipe` —
`parse_command` only ever stops its loop for one of three reasons (ran out
of tokens, hit a failure, or hit a pipe), and the first two are already
handled by the time this `while (*tokens)` is reached, so the only way
`*tokens` can be non-`NULL` here is if it's sitting on a pipe. Re-checking
that would be validating something step 4 (and this function's own control
flow) already guarantees — exactly the kind of redundant defensive check
the project avoids adding. On failure, thanks to the invariant above,
`*tokens` is already fully handled by the failed `parse_command` call —
`parse()` only has to free the `t_cmd` nodes it had already linked
(`head`).

---

## 6. `src/shell/shell.c` and `src/shell/debug_pipeline.c` — wiring it in

```c
static void	process_line(t_shell *shell, char *line)
{
	shell->tokens = tokenize(line);
	free(line);
	if (shell->tokens && !validate_tokens(shell->tokens))
	{
		shell->exit_status = 2;
		free_tokens(shell->tokens);
		shell->tokens = NULL;
	}
	else if (shell->tokens)
	{
		shell->pipeline = parse(&shell->tokens);
		debug_print_pipeline(shell->pipeline);
		free_cmd(shell->pipeline);
		shell->pipeline = NULL;
	}
}
```
This is the same three-way branch step 4 already had (nothing to do /
syntax error / valid), just with the "valid" branch now doing something
real: `parse(&shell->tokens)` — passing the *address* of the pointer,
since parsing consumes the list as it walks, mutating `shell->tokens`
down to `NULL` by the time it returns (every node ends up moved into the
AST or freed directly). `debug_print_pipeline` is the direct replacement for
step 3-4's `debug_print_tokens`, existing for the same reason: making the
parser's output visible while testing, until step 7 (execution) replaces
it with real consumption of the AST.

This function is new in this step, but not because parsing demanded it —
`shell_loop` itself hit Norminette's 25-line limit once the `parse` branch
was added, so this logic was extracted verbatim into its own
`static` helper. Splitting a function to satisfy the norm, rather than
reaching for anything looser, is the same move made when `tokenize` was
kept short by factoring out `next_token` back in step 3.

```c
void	shell_loop(t_shell *shell)
{
	char	*line;

	while (1)
	{
		line = readline("minishell$ ");
		if (!line)
		{
			ft_putstr_fd("exit\n", STDOUT_FILENO);
			break ;
		}
		if (*line)
			add_history(line);
		process_line(shell, line);
	}
}
```
Now just the read-loop skeleton: read a line, handle Ctrl-D, record
history, hand the line off. `process_line` takes ownership of `line`
(frees it right after `tokenize`), so nothing here needs to free it
itself.

`debug_print_pipeline` (in the new `src/shell/debug_pipeline.c`, not `shell.c`
itself) walks the `t_cmd` list, printing each command's `args` fragment
chain and each redirection's operator symbol plus its own target fragment
chain — the same flat, unglamorous "print every field" style as step 3's
`debug_print_tokens`, just now aware of the list-shaped
data. It was put in its own file rather than added to `shell.c` purely to
stay under Norminette's function-count-per-file limit once four small
printing helpers were needed — same reasoning as the `process_line` split
above, just applied to a different limit.

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `process_line`
-> `tokenize` (same chain as step 3) -> if tokens exist, `validate_tokens`
(same chain as step 4) -> on success, `parse` (-> `parse_command` in a loop
-> `parse_token` -> `take_word` / `consume_redir` -> `redir_type` /
`append_redir`, per token; `skip_pipe` between commands) -> on success,
`debug_print_pipeline` (-> `print_word` / `print_redirs`); on any parser failure
(allocation only — grammar is already guaranteed by step 4),
`shell->pipeline` stays `NULL` -> `free_cmd` -> loop back to `readline`.

Verified interactively with piped test lines covering a single command, a
multi-stage pipeline, a redir-only command, redirections interleaved with
arguments on both sides, a heredoc token pair, and the running
multi-fragment-word example from step 3, plus a re-run of every step 4
syntax-error case to confirm nothing regressed. `valgrind
--leak-check=full`: 0 definitely/indirectly/possibly lost bytes.

Nothing is expanded or executed yet — that starts at **Step 6 (expansion:
env vars, `$?`, quote removal, word splitting)** per `PROGRESS.md`.

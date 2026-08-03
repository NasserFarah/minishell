# Step 4 — Line-by-line explanation

Covers **Step 4 — Token validation / syntax errors**, per `PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/minishell.h` (new declarations) ->
`src/tokenizer/tokenizer_validate_utils.c` (the error-printing helper) ->
`src/tokenizer/tokenizer_validate.c` (the actual grammar checks) ->
`src/shell/shell.c` (wiring + what changes vs. step 3).

---

## 0. What the subject actually requires here (checked first)

This is the one step so far where `en.subject.pdf` has **no grammar spec at
all** to check against — it never mentions "syntax error," never lists
what makes a token stream invalid, nothing. The only relevant sentence in
the whole document is the general fallback: *"If you have any doubt about
a requirement, take bash as a reference."* So before writing any code, the
actual reference consulted was live bash behavior for the token types that
exist in this project **right now**:

```
$ |
bash: syntax error near unexpected token `|'
$ echo |
bash: syntax error near unexpected token `newline'
$ echo | | ls
bash: syntax error near unexpected token `|'
$ >
bash: syntax error near unexpected token `newline'
$ echo > | cat
bash: syntax error near unexpected token `|'
$ < in | > out
(no error — runs fine)
```

That last case matters: it rules out a tempting-but-wrong rule of "a pipe
must have a word on each side." Bash treats a pipeline stage that's nothing
but redirections as perfectly valid (it just runs an empty command with
those redirections applied), so the validator below doesn't reject it.

Also checked `friend_minishell/src/tokenization/validation.c` for a second
opinion on structure. It validates pipes, redirections, heredocs,
`&&`/`||`, and parentheses as five separate functions, because its token
enum already has `TOKEN_AND`/`TOKEN_OR`/`TOKEN_LPAREN`/`TOKEN_RPAREN`. This
project's `t_token_type` doesn't have those yet (they're bonus, steps 9-10,
per the `t_token_type` decision already logged in step 3) — so only the
pipe and redirection checks apply. Writing checks for token types that
can't currently be produced would be speculative code the subject doesn't
ask for ("anything not asked is not required").

---

## 1. `inc/minishell.h` — new declarations

```c
int		validate_tokens(t_token *tokens);
void	print_syntax_error(t_token *near);
```

Same convention as step 3: every cross-file function gets declared here,
even ones (like `print_syntax_error`) that are really an internal helper
for the tokenizer module rather than something `main.c` would call. Only
`validate_tokens` is the module's real public API — `shell_loop` calls
that one and nothing else from these two new files.

---

## 2. `src/tokenizer/tokenizer_validate_utils.c` — printing the error

```c
static const char	*op_text(t_token_type type)
{
	if (type == TOKEN_PIPE)
		return ("|");
	if (type == TOKEN_REDIR_IN)
		return ("<");
	if (type == TOKEN_REDIR_OUT)
		return (">");
	if (type == TOKEN_REDIR_APPEND)
		return (">>");
	return ("<<");
}
```
Maps an operator token type back to the exact text bash would print for
it. Only ever called with an operator type (never `TOKEN_WORD`) — the
caller in `tokenizer_validate.c` only reaches for this when it already
knows the token in question is one of the five operator kinds, so the
final unconditional `return ("<<")` is safe as the last remaining case,
not a silent wrong-answer fallback.

```c
void	print_syntax_error(t_token *near)
{
	ft_putstr_fd("minishell: syntax error near unexpected token `",
		STDERR_FILENO);
	if (near)
		ft_putstr_fd((char *)op_text(near->type), STDERR_FILENO);
	else
		ft_putstr_fd("newline", STDERR_FILENO);
	ft_putstr_fd("'\n", STDERR_FILENO);
}
```
Builds the message in three `ft_putstr_fd` calls to `STDERR_FILENO` (a
real error goes to stderr, not stdout — same channel bash itself uses).
`near` is the token bash would point at as "the unexpected one":
- A real token pointer -> prints that token's text between the backtick
  and the closing quote (`` `|' ``, `` `<<' ``, etc.).
- `NULL` -> prints the literal word `newline`, matching bash's own
  convention of naming the *absence* of a next token (end of input) as if
  it were a token called `newline` — this is really bash's own quirk of
  phrasing, not something invented here; it's exactly what real bash prints
  for `echo |` or a bare `>`.

---

## 3. `src/tokenizer/tokenizer_validate.c` — the actual grammar

```c
static int	is_redir(t_token_type type)
{
	return (type == TOKEN_REDIR_IN || type == TOKEN_REDIR_OUT
		|| type == TOKEN_REDIR_APPEND || type == TOKEN_HEREDOC);
}
```
One predicate covering all four "this operator needs a filename/delimiter
after it" token types, so the check below doesn't have to repeat itself
four times.

```c
static int	validate_pipes(t_token *tokens)
{
	t_token	*prev;

	prev = NULL;
	while (tokens)
	{
		if (tokens->type != TOKEN_PIPE)
		{
			prev = tokens;
			tokens = tokens->next;
			continue ;
		}
		if (!prev)
			return (print_syntax_error(tokens), 0);
		if (!tokens->next)
			return (print_syntax_error(NULL), 0);
		if (tokens->next->type == TOKEN_PIPE)
			return (print_syntax_error(tokens->next), 0);
		prev = tokens;
		tokens = tokens->next;
	}
	return (1);
}
```
Walks the list once, tracking `prev` (the previous node) as it goes.
Non-pipe tokens just advance the walk (`continue`). For a `TOKEN_PIPE`,
three ways it can be invalid, checked in the order bash would actually hit
them:
- **`!prev`** — this pipe is the very first token on the line (nothing
  came before it). The unexpected token bash reports here is the pipe
  *itself*, so `print_syntax_error(tokens)` — not `tokens->next` — is what
  gets passed.
- **`!tokens->next`** — this pipe is the last token (nothing after it).
  Bash reports this as hitting end-of-input, i.e. `` `newline' ``, so
  `print_syntax_error(NULL)`.
- **`tokens->next->type == TOKEN_PIPE`** — two pipes in a row. The
  unexpected token here is the *second* pipe, so
  `print_syntax_error(tokens->next)`.

If none of those hit, `prev`/`tokens` advance normally. Note what's
*absent*: no check that `tokens->next` (when it exists and isn't another
pipe) is specifically a `TOKEN_WORD` — as covered in section 0, a
redirection is a perfectly valid thing to find right after a pipe
(`cmd | > out`), so that case is deliberately allowed through here.

```c
static int	validate_redirs(t_token *tokens)
{
	while (tokens)
	{
		if (is_redir(tokens->type) && !tokens->next)
			return (print_syntax_error(NULL), 0);
		if (is_redir(tokens->type) && tokens->next->type != TOKEN_WORD)
			return (print_syntax_error(tokens->next), 0);
		tokens = tokens->next;
	}
	return (1);
}
```
For every redirection-family token (`<`, `>`, `>>`, `<<`):
- If there's no next token at all, that's `` `newline' `` — a redirection
  can never legally be the last token on a line, it always needs a target.
- Otherwise, if the next token isn't a `TOKEN_WORD`, report the syntax
  error near *that* token (whatever operator it turned out to be).

The two `if`s look like they could null-deref on the second line when
`tokens->next` is `NULL`, but they can't: the first `if` already returns
whenever `is_redir(tokens->type) && !tokens->next` is true, so by the time
control reaches the second `if`, either `is_redir(tokens->type)` is false
(short-circuits before touching `tokens->next` at all) or `tokens->next` is
guaranteed non-`NULL`. This one check also transitively catches
back-to-back redirections like `> >` — the first `>`'s "next" is another
operator token, not a word, so it's rejected without needing a dedicated
"two redirections in a row" branch.

```c
int	validate_tokens(t_token *tokens)
{
	if (!validate_pipes(tokens))
		return (0);
	if (!validate_redirs(tokens))
		return (0);
	return (1);
}
```
The module's one public entry point: run both checks, short-circuiting on
whichever fails first (each sub-check has already printed its own error
before returning `0`, so `validate_tokens` itself never prints anything —
it only decides pass/fail).

---

## 4. `src/shell/shell.c` — wiring it in

```c
shell->tokens = tokenize(line);
free(line);
if (shell->tokens && !validate_tokens(shell->tokens))
	shell->exit_status = 2;
else
	debug_print_tokens(shell->tokens);
free_tokens(shell->tokens);
shell->tokens = NULL;
```

Compared to step 3, three things changed:
- `free(line)` moved up right after `tokenize(line)` — the line's raw text
  is never needed again past that call, so there's no reason to keep
  holding it while validation runs. Purely a reordering, not a behavior
  change.
- `shell->tokens && !validate_tokens(shell->tokens)` — validation only
  runs when `tokenize` actually produced something. A blank line (or a
  line that's only whitespace) still yields `shell->tokens == NULL` with
  no error, same as step 3; there's nothing to validate. A line that
  failed at the *tokenizer* level (unclosed quote) also already returned
  `NULL` with its own error already printed by step 3's code — that path
  is untouched here, validation simply never sees a token list in that
  case either.
- On a validation failure, `shell->exit_status = 2` (bash's real exit
  status for a shell syntax error — logged as Decision #5 in
  `PROGRESS.md`) and `debug_print_tokens` is skipped, so a rejected token
  stream is never shown on screen as if it had been accepted. On success,
  behavior is byte-for-byte identical to step 3: print the tokens, free
  them, keep looping.

This is still the same temporary scaffolding step 3 introduced —
`debug_print_tokens` still exists purely so the tokenizer's output stays
visible while testing. Step 5 (parser) is what finally replaces it with
real consumption of a *validated* token stream into an AST.

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `tokenize`
(same chain as step 3) -> if tokens exist, `validate_tokens`
(-> `validate_pipes`, then `validate_redirs`, either possibly calling
`print_syntax_error` -> `op_text`) -> on success, `debug_print_tokens`; on
failure, `shell->exit_status = 2` instead -> `free_tokens` -> loop back to
`readline`.

Verified interactively with a batch of piped lines exercising every branch
above (leading pipe, trailing pipe, double pipe, dangling redirection,
redirection-then-pipe, a valid multi-stage pipeline, a valid redir-only
stage, a valid `>>`, a valid heredoc pair) — every case matched real bash's
message shape or lack of error exactly. `valgrind --leak-check=full` over
the same batch: 0 definitely/indirectly/possibly lost bytes.

Nothing is parsed or executed yet — that starts at **Step 5 (parser: build
AST)** per `PROGRESS.md`.

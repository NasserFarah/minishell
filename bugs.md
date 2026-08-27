# Minishell — Mandatory Part Bug Audit

Found via: `norminette`, `valgrind` (with `readline.supp`), the differential test
suite (`tests/run_tests.sh`, diffs against real bash), and `tests/pty/signal_tests.py`.
Ordered most severe first.

## 1. Uninitialized `open`/`close` locals → random false "syntax error" (critical)

`src/tokenizer/tokenizer_word.c:52-70`, `parse_bare_segment()`.

`int open; int close;` are declared with no initializer and only ever set to `1`
if a `(`/`)` is seen. For any word without parens (almost every normal word),
`new_token(TOKEN_WORD, line, open, close)` reads garbage stack values.
`brace_syntax()` (`tokenizer_validate.c:63`) later branches on `token->open`/
`token->close`, so garbage bits randomly trigger a false
`syntax error near unexpected token ')'` and reject an otherwise valid command.

- Confirmed via valgrind: `Conditional jump or move depends on uninitialised
  value(s)` at `tokenizer_validate.c:63`, on essentially every command tested.
- Confirmed functionally: a 3000-word `echo …` line failed outright with
  `minishell: syntax error near unexpected token ')'`, exit 2 — while the same
  line typed interactively happened to survive (different stack garbage).
- Eval sheet explicitly requires "a long command with a ton of arguments" to
  not break.
- Fix: `open = 0; close = 0;` before the loop.

## 2. Heredoc delimiter is expanded before being used to match the terminator

`src/expansion/expand_redirs.c`, `expand_cmd_redirs()` calls
`expand_fragments(redir->target, shell)` unconditionally, including for
`REDIR_HEREDOC`. Per POSIX/bash, the delimiter word is never expanded — only
the heredoc *body* expansion should depend on `heredoc_expand`.

Repro: `cat << $HOME` then type lines — minishell expands `$HOME` to the real
value immediately and uses that as the terminator, so a body line equal to
`$HOME`'s value silently ends the heredoc early, and everything after leaks
out as bogus top-level commands. Real bash keeps the terminator as the
literal text `$HOME` always.

## 3. `cd` error messages never include the target path

`src/builtin_functions/builtin_cd.c` (`lone()`, `minus()`, and the direct
`chdir()` branch in `builtin_cd()`) all call bare `perror("minishell: cd")`,
which only prints `strerror(errno)`, never the offending argument.

- Bash: `cd: Makefile: Not a directory`
- Minishell: `cd: Not a directory`

100% reproducible on every failing `cd`. Explicit mandatory checklist item.

## 4. `cd -` never prints the new working directory

`src/builtin_functions/builtin_cd.c`, `minus()`: changes to `$OLDPWD`
correctly but never echoes it to stdout. Real bash always prints the new pwd
on `cd -` (unlike a normal `cd`, which is silent).

Repro: `cd /tmp; cd /repo; cd -` → bash prints `/tmp`; minishell prints
nothing.

## 5. `exit` argument handling is wrong in three ways

`src/builtin_functions/builtin_exit.c`:

- `non_numeric_exit()` hardcodes `shell->exit_status = 255`; bash uses **2**
  for "numeric argument required" (`exit: hola: numeric argument required` →
  `$?=2`, confirmed against live bash).
- `builtin_exit()` checks `arg->next` (too many args) *before* checking
  `is_numeric()`. Bash validates numeric-ness of arg 1 first: `exit hola que
  tal` exits the shell with status 2 and the numeric-argument message;
  minishell instead prints "too many arguments" and does not exit.
- `exit_code_mod()`'s overflow-length guard (`i > 19 && !neg`) is off-by-one
  for 19-digit unsigned overflow (e.g. `9223372036854775808`,
  `INT64_MAX+1`) — doesn't trigger, so it silently returns a wrapped garbage
  exit code (0) instead of erroring. Also, when the guard *does* trigger, it
  calls `non_numeric_exit()` for its side effects but doesn't `return` —
  execution falls through and `shell->exit_status` gets overwritten again by
  the wrapped value.

## 6. Heredoc-phase Ctrl-C still leaks unterminated input into the next command

Known issue, still open (out of scope of the last SIGINT/heredoc fix pass).
Typing unterminated text at a heredoc `> ` prompt, then Ctrl-C, then a new
command — the partial text concatenates with the next real command line.

Repro (pty): `cat << EOF` + `partial_no_newline` + Ctrl-C + `echo CLEAN=$?` →
runs as `minishell: partial_no_newlineecho: command not found` instead of a
clean next prompt.

Root cause: heredoc reading bypasses readline (which used to flush pending
tty input on signal); the raw `get_next_line`-based reader has no equivalent
flush.

## 7. Norm violations (auto-0 at defense if untouched)

- `src/execution/heredoc.c` — missing 42 header block entirely (just two
  blank lines before `#include`).
- `src/builtin_functions/builtin_env.c` — `builtin_env()` is 29 lines, over
  the 25-line cap.
- Already known/accepted, not new: `GLOBAL_VAR_DETECTED` notice on `g_signal`
  in `inc/minishell.h` (intentional, the project's one allowed global), and
  `MISALIGNED_FUNC_DECL` errors on the `gnl` prototype block near the end of
  the same file.

## 8. `$PWD`/`env` not resynced with the real cwd at shell startup

`src/env/env.c`, `env_init()` just copies `envp` verbatim. Real bash always
calls `getcwd()` at startup and sets/exports `PWD` to the actual cwd,
overriding whatever was inherited.

Repro: launch minishell with `PWD` unset or stale in the environment —
`$PWD`/`env`/`export` show the wrong (or empty) value even though `pwd`
(which calls `getcwd()` directly) is correct. This is also the root cause of
most of the `env`/`export` differential-test failures — dozens of "stdout
differs" cases were really just this single divergence.

---

## Checked clean / out of scope

- Build: clean with `-Wall -Wextra -Werror`, no relink on a no-op `make`, no
  warnings.
- Forbidden-function grep: no hits for `system`/`popen`/`setenv`/`putenv`/
  `getline`/`scanf`/`wordexp`/`glob`.
- General memory leaks: nothing beyond the uninitialized read in bug #1 (no
  "definitely/indirectly lost" bytes in any scenario tried).
- Signals: the 7 automated `tests/pty/signal_tests.py` cases pass; manually
  re-verified Ctrl-\ at idle prompt is a no-op, Ctrl-C with pending text
  discards the buffer correctly at the main prompt.
- Pipes/redirections/binaries/edge-case categories: no new root causes beyond
  #2/#3/#8 above.
- Empty command, spaces/tabs-only, bogus command (exit 127), `cd .`/`cd ..`,
  relative paths, basic `$PATH` lookup: all match bash.
- Bonus/POSIX-extension syntax (`&&`, `||`, `;`, `()`, wildcards, backslash
  escaping, here-strings, `$"..."`/`$'...'`, `+=`) intentionally not counted
  against you since only the mandatory part was implemented — but none of it
  crashes the shell either.
- Terminal resize (`SIGWINCH`) while a prompt is being edited can garble the
  redisplay (stale line-wrap/width). Root cause is a known upstream bug in
  the installed `libreadline 8.1.2` (Ubuntu 22.04) itself: fixing it requires
  `rl_resize_terminal()`/`rl_forced_update_display()`, or toggling the
  `rl_catch_sigwinch` variable so an app-installed `SIGWINCH` handler can run
  instead of readline's own — none of which are in the subject's allowed
  function list (`readline, rl_clear_history, rl_on_new_line, rl_replace_line,
  rl_redisplay, add_history, ...`). Readline also reinstalls its own
  `SIGWINCH` handler internally on every `readline()` call by default, so an
  app-level `sigaction(SIGWINCH, ...)` handler built only from whitelisted
  calls wouldn't even run during the corrupted window. Same category as the
  already-accepted readline-internal-state notes above; not fixable from
  student code under the given constraints.

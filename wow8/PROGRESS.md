# Minishell — my own rebuild — progress log

Not a project doc (see README.md for that once it exists) — this is a
working log so a session can resume exactly where the last one stopped.

## Working agreement

- Own code, own naming, but same overall architecture as the reference
  project studied first: tokenizer -> parser (AST) -> expansion -> execution.
- Strict subject scope: "anything not asked is not required". Two explicit
  deviations from the reference project already made (see Decisions below).
- Workflow: build one step, explain it fully, confirm understanding, THEN
  move to the next step. Don't skip ahead.
- Norm: check with `norminette src inc` after every step. Only acceptable
  warning is GLOBAL_VAR_DETECTED on `g_signal` (required by subject).

## Architecture overview

```
readline() -> tokenizer -> token validation -> parser (AST) ->
    expansion (per command args) -> execution (walks AST) -> builtins/execve
```

Core structs (grow as we go, currently in `inc/structs.h`):
- `t_env`   : linked list, key/value/next (parsed from envp at startup)
- `t_token` : linked list, one node per quote-run segment of a word (or one
  node for an operator); see Step 3 log below for the segment/join_next model.
  Reused as-is for `t_cmd.args` and `t_redir.target` (see Decision #7) and,
  post-expansion, for the final flattened `argv` words too (Step 6).
- `t_redir` : one redirection (`type`, `target` word, `heredoc_expand`/
  `heredoc_fd` for `<<` only — Decision #14), linked list per command
- `t_cmd`   : one pipeline command (`args`, `redirs`, `next`) — a flat
  linked list *is* the pipeline; no separate tree node exists yet
  (Decision #6), since only `|` exists until bonus step 9 adds `&&`/`||`
- `t_shell` : env, exit_status, interactive flag, `should_exit` (Step 8 —
  set only by the `exit` builtin, checked by `shell_loop` to terminate
  cleanly through the normal `free_shell` path rather than a raw `exit()`),
  tokens, `ast` (head `t_cmd`)
- `t_split` : implementation-detail accumulator for Step 6's word-splitting
- `t_pipeline` : implementation-detail bundle for Step 7's fork/pipe/wait
  bookkeeping (`n_cmds`, flat `pipes` fd array, `pids` array)

## Step checklist

- [x] Step 1 — Project skeleton: Makefile, headers, REPL loop
- [x] Step 2 — Signal handling baseline
- [x] Step 3 — Tokenizer
- [x] Step 4 — Token validation / syntax errors
- [x] Step 5 — Parser: build AST
- [x] Step 6 — Expansion: env vars, $?, quote removal, word splitting
- [x] Step 7 — Execution engine
- [x] Step 8 — Builtins: echo, cd, pwd, export, unset, env, exit
- [ ] Step 9 — Bonus: && || with parentheses
- [ ] Step 10 — Bonus: wildcard expansion
- [ ] Step 11 — README.md

## Decisions / scope calls (deliberately different from the reference project)

1. **No `~` (tilde) expansion.** Not mentioned anywhere in the subject text.
2. **No unclosed-quote line continuation.** Subject explicitly says this is
   not required.
3. Single global is `volatile sig_atomic_t g_signal` — stores ONLY the
   signal number, nothing else, per the subject's warning box.
4. Syntax-error wording deliberately mirrors real bash (`` minishell: syntax
   error near unexpected token `X' ``, `` `newline' `` when nothing follows
   an operator) rather than inventing our own phrasing. The subject has no
   grammar spec for this step at all — it only says "if in doubt, take bash
   as reference" — so bash's own message shape was taken as the spec.
5. On a syntax error, `shell->exit_status` is set to `2`, matching bash's
   real exit status for a shell syntax error. Nothing in the subject states
   this explicitly; it's the same "take bash as reference" call as #4.
6. The AST is a flat singly-linked list of `t_cmd` (one pipeline), **not**
   a generic binary tree with a `t_node`/`NODE_PIPE` wrapper the way
   `friend_minishell` builds it. Only `|` exists in scope right now — a
   tree adds branching power that's only needed once `&&`/`||`/`()` exist
   (bonus, step 9). A flat list is the simplest structure that correctly
   represents "one or more commands piped together" today; a real tree
   (pipelines as leaves, `AND`/`OR` as internal nodes, parens as grouping)
   is the natural extension to introduce *when* step 9 actually adds those
   operators, not before.
7. `t_cmd.args` and `t_redir.target` are both plain `t_token *` — the same
   struct the tokenizer already produces — rather than inventing a
   parallel `t_arg`/`t_filename` type that would just duplicate
   `value`/`single_quoted`/`double_quoted`/`join_next`/`next`. A command's
   arguments and a redirection's filename/delimiter are both just "a shell
   word, not yet expanded," and a word is exactly what a `t_token`
   fragment-chain already represents. This also means a multi-fragment
   redirection target (e.g. `> "$HOME"/out`) round-trips correctly, since
   the fragment chain (and each fragment's quoting) survives into the AST
   unflattened, ready for step 6 to expand and splice.
8. **No `$$` (PID) expansion.** The subject only ever mentions "`$`
   followed by a sequence of characters" (a variable) and `$?` — nothing
   about the shell's own PID. A `$` followed by anything that isn't a
   valid identifier start (`[A-Za-z_]`) or `?` is left completely literal,
   so `$$` prints as literal `$$`, not a process ID.
9. **No positional parameters.** `$1`, `$9`, etc. are bash features for
   script arguments; the subject never mentions shell arguments at all.
   A `$` followed by a digit is therefore left literal too (same rule as
   Decision #8 — only `[A-Za-z_]` or `?` after `$` triggers expansion).
10. **Redirection targets are expanded but never word-split.** Real bash
    *does* word-split a redirection's filename/delimiter too — and errors
    with "ambiguous redirect" if that split produces more than one word.
    The subject never mentions this at all, and building that error path
    would require deciding how it interacts with execution's not-yet-built
    error reporting (step 7) for a corner case unlikely to be tested. So a
    redirection target's fragments (quoted or bare) are all expanded, then
    simply concatenated into exactly one final string — if that string
    happens to contain whitespace (e.g. an unquoted `$VAR` with a space in
    its value used as a filename), it becomes one unusual-but-valid
    filename rather than splitting or erroring.
11. **Malloc-failure handling in the expansion module matches
    `friend_minishell`'s own standard, not steps 1-5's stricter one.**
    Steps 1-5 checked and propagated every single allocation's result.
    Expansion involves dozens of tiny intermediate `ft_strjoin`/
    `ft_substr` calls per word; checking every one of them (the reference
    project doesn't either — see `expand_variables.c`'s `append_to_result`)
    would be exactly the kind of defensive code my own working
    instructions say not to add "for scenarios that basically can't
    happen." The structural allocations that matter (`new_token`, the
    `t_redir`/`t_cmd` mallocs from step 5) are still checked; the small
    string-building helpers are not, on the judgment that a `malloc`
    failing on a few dozen bytes for one shell input line is not a
    realistic failure mode worth the added complexity.
12. **Every pipeline stage always forks, even a single non-piped command
    with no pipe at all.** Real bash skips forking for some single-command
    cases (so a builtin like `cd` can mutate the shell's own state). Since
    no builtins exist until step 8, there is nothing that *needs* to run
    without forking yet — always forking is the simplest uniform model for
    now. Step 8 is where a "don't fork for a single builtin" exception
    belongs, once there's a builtin whose whole point is mutating parent
    state.
13. **Heredoc bodies are buffered through a temp file, not a pipe.** A pipe
    has a fixed kernel buffer (commonly 64KB); writing a heredoc body of
    unbounded size into one before any reader process exists would risk
    the parent blocking forever on `write()`. `unlink` being in the
    subject's allowed-function list is a strong signal a temp-file
    approach is the anticipated technique. The temp file is opened,
    written, closed, reopened read-only, and unlinked immediately — Unix
    keeps the already-open read fd valid even after the name is removed,
    so nothing is left behind on disk and there's no cross-run collision
    window despite reusing one fixed path (no `getpid` is available in
    the allowed functions to make the name unique, and heredocs are
    resolved strictly sequentially within one process before any forking,
    so a fixed name never overlaps with itself).
14. **A heredoc delimiter is expanded to determine its text (e.g. `<<
    $X`), but the delimiter's own *quoting* — whether *any* fragment of it
    was single- or double-quoted — separately controls whether `$`
    expansion happens *inside the body*.** This is real, if slightly
    obscure, bash behavior, and it required a small retrofit to two
    already-"done" steps: `t_redir` gained `heredoc_expand`/`heredoc_fd`
    fields (structs.h), initialized in step 5's `consume_redir`, and step
    6's `expand_cmd_redirs` now records whether the original target had
    any quoted fragment *before* flattening it — since that flattening
    (needed for the delimiter text itself) would otherwise destroy the
    only place that quoting information lived. Noted here the same way
    the Makefile fix was noted under step 1: a gap found and fixed while
    building the step that actually needed the information, not silently
    left broken.
15. **Redirection failures exit the forked child with status 1; a missing
    or non-executable command exits with 127 or 126 respectively**,
    matching real bash's conventions (checked directly, not guessed) — a
    plain "command not found" for a `PATH`-searched name that doesn't
    exist anywhere, "Permission denied" (126) specifically when a
    candidate exists but fails `access(X_OK)`, distinguished via
    `access(F_OK)` vs `access(X_OK)` since libft/the allowed functions
    don't include anything that reads `errno` symbolically beyond
    `perror`/`strerror`.
16. **Ctrl-C during heredoc body entry does not abort the heredoc/command
    the way real bash does — it behaves exactly like Ctrl-C at the main
    prompt instead (fresh prompt, keep waiting for more heredoc lines).**
    This was attempted properly first: a heredoc-specific `SIGINT` handler
    forcing the current `readline()` call to return early via `rl_done`,
    detected afterward via `g_signal`, aborting the whole command with
    `exit_status = 130`. Tested under a real pty, it was **unreliable** —
    depending on exact byte-level timing, `rl_done` sometimes forced an
    early return and sometimes didn't (readline just kept waiting on the
    same call despite the flag), even after trying every readline-signal
    cleanup function documented for this exact purpose
    (`rl_free_line_state`, `rl_cleanup_after_signal`,
    `rl_clear_pending_input`). Shipping behavior that's inconsistent
    depending on timing no human can control is worse than shipping a
    simpler, *reliable* behavior — so this reuses the already-proven-solid
    main-prompt handler instead. `$?` still correctly becomes `130` when a
    **running foreground command** (not a heredoc) is killed by Ctrl-C —
    that path doesn't touch readline at all and was verified solid across
    many repeated pty runs. Worth revisiting later if a more reliable
    technique surfaces.
17. **Any of the seven builtins, when it's the *only* command on the line
    (no pipe), runs directly in the shell's own process — no `fork()` at
    all.** This is the exception step 7's Decision #12 explicitly deferred
    to this step. Matches real bash: a builtin as part of a multi-stage
    pipeline (`cd | true`) still forks (subshell semantics — it cannot
    affect the parent shell's own state, verified below), but a standalone
    one must run in-process for `cd`/`export`/`unset`/`exit` to have any
    effect on the shell at all. Applying this to *all seven* uniformly
    (not just the four that strictly need it) matches bash's own behavior
    and is simpler than special-casing a subset.
18. **A standalone builtin's own redirections are applied in the parent
    process and then explicitly undone afterward** (`run_standalone_
    builtin` in `standalone.c`: `dup` the real stdin/stdout aside before
    `apply_redirs`, `dup2` them back and close the saved copies after) —
    since there's no child process to die and take a permanent `dup2`
    with it, the interactive shell's own terminal I/O must be restored so
    the next prompt isn't left pointed at some redirected file.
19. **`export`/`unset` validate that each argument is a legal shell
    identifier** (`[A-Za-z_][A-Za-z0-9_]*`, optionally followed by `=` for
    `export`), printing "not a valid identifier" and returning status `1`
    for a bad one — checked directly against real bash's own behavior, not
    assumed. Not explicitly required by "no options," but it's core,
    easily-tested `export`/`unset` behavior, not an extra option.
20. **`export` with no arguments prints `declare -x KEY="value"` per
    variable, sorted alphabetically** — this is real bash's own output for
    bare `export`, checked directly rather than guessed, and a
    commonly-tested case. Sorting uses a small hand-written
    insertion-style sort over an array of `t_env*` pointers, since neither
    libft nor the subject's allowed functions include a generic sort.
21. **`export NAME` (no `=`) on a name that doesn't already exist creates
    it with an empty string value**, rather than reproducing bash's exact
    "declared but not yet in the environment until assigned" distinction
    (a variable can exist as an exported *name* in real bash without ever
    appearing in `env`'s output until it's given a value). This project's
    `t_env` list doubles as *both* the shell's variable store and the
    literal environment handed to `execve` — there's no separate
    not-yet-a-real-env-var state to represent that distinction cleanly, so
    the simplification is an empty value (visible in `env` as `NAME=`)
    rather than building a parallel "declared-only" bookkeeping system for
    a corner case the subject never mentions.
22. **`exit`'s argument handling matches bash's own three cases exactly,
    checked directly rather than assumed**: no argument exits with the
    shell's current `$?`; a single non-numeric argument prints "numeric
    argument required" and still exits, with status `255`; two or more
    arguments prints "too many arguments" and does **not** exit at all
    (the shell continues, `$?` becomes `1`). A numeric argument is reduced
    to `0-255` digit-by-digit under modular arithmetic
    (`(acc * 10 + digit) % 256` at every step) specifically so an
    arbitrarily long digit string can never overflow `int` — bash's own
    `exit` accepts and wraps very large numbers the same way.
23. **`export NAME=$VAR` is exempted from word-splitting on its value**,
    fixing a real, confirmed gap flagged (but deliberately left
    unaddressed until now) back in steps 6-7: since `expand_cmd_args`
    (step 6) had no concept of "this command is `export`," an unquoted
    `$VAR` whose value contains whitespace would incorrectly split
    `export FOO=$VAR` into `FOO=<first-word>` plus a separate bogus
    bare-name argument for each remaining word — verified this actually
    happened (`export FOO=$TESTVAR` with `TESTVAR="a b"` produced
    `FOO="a"` and a stray empty `b=""` variable) before fixing it, not
    just assumed from reading the code. The fix is narrow and contained
    entirely within `expand_cmd_args` (`expansion.c`): when the command is
    `export` and a later argument's first fragment matches `NAME=...`, its
    already-`$`-expanded fragments are joined *whole* (reusing the exact
    same `join_word` redirection-targets already use, promoted to
    non-static and moved to a new `expand_redirs.c` alongside
    `expand_cmd_redirs` — itself relocated purely to keep `expansion.c`
    under Norminette's 5-functions-per-file limit once this logic was
    added) instead of going through `split_word`. `unset` was not given
    the same treatment since it never takes `NAME=VALUE` arguments.

## Step-by-step log

### Step 1 — Skeleton (done)

Files: `Makefile`, `inc/minishell.h`, `inc/structs.h`, `src/main/main.c`,
`src/shell/shell.c`, `src/env/env.c`.

- Makefile builds `libft/libft.a` via its own Makefile first, then compiles
  `src/**/*.c` into mirrored `obj/**/*.o`, using `-MMD -MP` generated `.d`
  files (`-include $(DEPS)`) so a header change triggers exactly the
  objects that depend on it — no full rebuilds, no unnecessary relinking.
- `main.c`: builds `t_shell` from `envp` (`env_init`), calls `init_signals`,
  runs `shell_loop`, frees, returns `shell.exit_status`.
- `env.c`: splits each `"KEY=VALUE"` on the first `=` into a `t_env` node,
  appended to a linked list (handles the edge case of an exported var with
  no `=`, e.g. malformed entries, by storing `value = NULL`).
- `shell.c`: `readline("minishell$ ")` loop; non-empty lines go to history;
  `NULL` return (Ctrl-D / real EOF) breaks the loop and prints `exit`.
  `shell` param currently unused (`(void)shell;`) — will be used once we
  wire in tokenize/parse/execute in step 3+.

### Makefile fix (found during step 1 review)

`$(LIBFT): $(LIBFT_SRCS) $(LIBFT_HDRS)` — originally this rule had **no
prerequisites**, just the recipe. Make's rule: a target with no
prerequisites, once the target file exists, is considered up to date
forever (nothing can be "newer than nothing"), so the sub-make into
`libft/` silently never ran again after the first build — editing a libft
source and running `make` was a no-op. Fixed by giving it real
prerequisites (`wildcard libft/*.c libft/*.h`) so make's timestamp check
actually has something to compare against. Verified: touching a libft
source now triggers rebuild+relink; touching only a `src/` file rebuilds
just that object and relinks, without re-entering `libft/`; a second
`make` with nothing changed is a true no-op.

### Step 2 — Signals (done)

File: `src/shell/signals.c`.

- `g_signal` global, `sigaction` for `SIGINT` (not plain `signal()`, so we
  control flags explicitly), `SIG_IGN` for `SIGQUIT` in interactive mode.
- Handler: `write(1, "\n", 1)` (async-signal-safe) then
  `rl_on_new_line(); rl_replace_line("", 0); rl_redisplay();` to hand
  readline back a blank line and redraw the prompt instead of killing the
  process.
- Verified under a *real* pty (Python `pty.fork()`, not just piped stdin —
  piped stdin has no controlling terminal so `^C` never generates SIGINT):
  Ctrl-C -> fresh prompt, shell survives. Ctrl-D -> clean exit, code 0.

### Step 3 — Tokenizer (done)

Files: `src/tokenizer/tokenizer.c`, `src/tokenizer/tokenizer_word.c`,
`src/tokenizer/tokenizer_utils.c`. Struct additions: `t_token_type` enum,
`t_token` struct, `t_shell.tokens` field, all in `inc/structs.h`.

- Checked the subject before writing anything: mandatory scope for this
  step is exactly `|`, `<`, `>`, `<<`, `>>`, plus single/double quote
  handling. No `\`, `;`, `&&`/`||`, parentheses, or wildcard token type —
  those are either explicitly forbidden (`\`, `;`) or bonus-scoped later
  (steps 9-10), so the enum only has `TOKEN_WORD`/`TOKEN_PIPE`/
  `TOKEN_REDIR_IN`/`TOKEN_REDIR_OUT`/`TOKEN_REDIR_APPEND`/`TOKEN_HEREDOC`.
- **Segment model**: one word can become *several* linked `t_token` nodes
  if its quoting changes mid-word (e.g. `echo "Hello, "$USER'!'` — a very
  common minishell test case). Each node covers one contiguous quote-run
  (bare / single-quoted / double-quoted), stores the quote-stripped text,
  and sets `join_next = 1` if the next node is part of the *same* word (no
  unquoted whitespace between them). This preserves per-segment quoting
  info that a single flattened string would lose — needed later so
  expansion (step 6) knows exactly which parts may see `$` expansion
  (bare/double-quoted) and which must not (single-quoted), then re-joins
  same-word segments into one final argv string.
- Quoting inside a token is fully stripped and independent per quote type:
  scanning a `'...'` or `"..."` run only looks for its own matching quote
  character; the other quote character and all operator characters are
  literal inside it. `\` and `;` are never special anywhere (per subject).
- Unterminated quote -> printed immediately (`minishell: unclosed quote`)
  and the whole token list built so far is freed, `tokenize()` returns
  `NULL`. This is a *lexical* error (quote matching), so it's handled here
  rather than deferred to step 4, which will instead validate the resulting
  *token stream* (e.g. a pipe with nothing after it) — a grammar-level
  concern that can't be caught while still scanning characters.
- `shell_loop` now actually uses its `shell` parameter: calls `tokenize`,
  hands the result to a temporary `debug_print_tokens` (in `shell.c`) to
  visually verify the token stream, then frees it. This print is scaffolding
  only — step 5 (parser) replaces it with real consumption of the tokens
  into an AST; noted here so it isn't mistaken for a permanent feature.
- Verified with piped-input smoke tests: mixed-quote words, pipes, all four
  redirection operators, empty quotes (`''`/`""` must still produce an
  empty-string `WORD`, not be skipped), a lone unterminated quote, and a
  blank line. Also ran under `valgrind --leak-check=full`: 0 definitely/
  indirectly/possibly lost — the only "still reachable" bytes are
  readline's own internal state, which the subject explicitly excuses.
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal` (same as step 2).

Full walkthrough: `docs/STEP_03_EXPLAINED.md`.

### Step 4 — Token validation / syntax errors (done)

Files: `src/tokenizer/tokenizer_validate.c`, `src/tokenizer/
tokenizer_validate_utils.c`. Header additions: `validate_tokens`,
`print_syntax_error` prototypes in `inc/minishell.h`.

- Checked the subject again before writing anything: it defines no grammar
  for this step, only "if you have any doubt about a requirement, take bash
  as a reference." So the checks implemented are exactly the ones bash's
  own parser enforces for the token types that exist *right now*
  (`TOKEN_PIPE`, the three redirections, `TOKEN_HEREDOC`) — nothing for
  `&&`/`||`/parentheses, since those token types don't exist yet (bonus,
  steps 9-10) and validating tokens that can't be produced would be
  speculative code the subject doesn't ask for.
- `validate_pipes`: a `|` is invalid if it's the first token (nothing
  before it), the last token (nothing after it), or immediately followed
  by another `|`. Deliberately does **not** require a `TOKEN_WORD` on
  either side of a pipe — bash accepts e.g. `< in | > out` (each pipeline
  stage may consist of nothing but redirections), so that's not an error.
- `validate_redirs`: any of `<`, `>`, `>>`, `<<` must be followed by a
  `TOKEN_WORD` (the filename or heredoc delimiter) — missing entirely, or
  followed by another operator, is rejected. This also transitively
  catches back-to-back redirection operators (`> >`) without a separate
  check, since the first one's "next" is an operator, not a word.
- Error message format matches bash verbatim (see Decisions #4 above):
  `` minishell: syntax error near unexpected token `|' `` etc., printed to
  stderr via `ft_putstr_fd`. `print_syntax_error(NULL)` prints `` `newline' ``
  for the "nothing follows" case, matching bash reporting the unexpected
  end-of-input as the token named `newline`.
- Wiring in `shell_loop`: after `tokenize()` succeeds, `validate_tokens` is
  called; on failure `shell->exit_status` is set to `2` (bash's real exit
  status for a syntax error, see Decisions #5) and the temporary
  `debug_print_tokens` call is skipped so a rejected token stream is never
  shown as if it were fine. On success, behavior is unchanged from step 3.
- Verified with a batch of piped test lines covering: a valid simple
  command, a lone leading pipe, a trailing pipe, a double pipe, a lone
  redirection with nothing after it, a redirection immediately followed by
  a pipe, a valid `cmd < file | cmd` pipeline, a valid redir-only stage
  (`> out`), a valid `>>` append, and a valid heredoc token pair — every
  case matched bash's real message shape (or lack of error) exactly.
  `valgrind --leak-check=full` over the same batch: 0 definitely/
  indirectly/possibly lost (same readline-only "still reachable" bytes as
  step 3).
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal`.

Full walkthrough: `docs/STEP_04_EXPLAINED.md`.

### Step 5 — Parser: build AST (done)

Files: `src/parser/parser.c`, `src/parser/parser_redir.c`,
`src/parser/parser_utils.c`. Struct additions: `t_redir_type` enum,
`t_redir`/`t_cmd` structs, `t_shell.ast` field, all in `inc/structs.h`.
Header additions: `parse`, `new_cmd`, `take_word`, `consume_redir`,
`free_cmd` prototypes, plus temporary `debug_print_ast` (in
`src/shell/debug_ast.c`), all in `inc/minishell.h`.

- Checked the subject and `friend_minishell` before writing anything (see
  Decisions #6-#7 above): the subject has no parser grammar at all beyond
  what's implied by "pipes" and "redirections" as separate features, and
  the reference project's `t_node`/`NODE_PIPE` binary-tree design exists to
  support `&&`/`||`/parentheses — none of which are in scope until step 9.
  Building that tree machinery now, for a grammar that today is just "zero
  or more pipes joining simple commands," would be exactly the kind of
  ahead-of-the-checklist abstraction the working agreement forbids. So the
  AST for now is a flat singly-linked list of `t_cmd`, each holding its own
  `args`/`redirs`.
- **Key design choice**: `t_cmd.args` and `t_redir.target` are both plain
  `t_token *` — the exact same fragment-chain type the tokenizer already
  produces (Decision #7). Parsing never flattens a word into a `char *`;
  it just decides *which* fragment-chain belongs where (which whole words
  are arguments vs. which single word is a given redirection's target),
  then physically moves those nodes out of `shell->tokens` into the AST.
  Nothing is copied or re-allocated — every `t_token` node tokenize()
  built ends up owned by exactly one place: an arg-chain, a target-chain,
  or freed directly (operator tokens, once their meaning is extracted).
- `take_word()` (`parser_utils.c`): detaches exactly one shell word — the
  current token plus every token chained after it via `join_next` — from
  the front of `*tokens`, re-terminates it as its own standalone chain, and
  advances `*tokens` past it. Used identically for a command argument and
  a redirection target, since both are "one word, possibly multiple
  quote-fragments."
- `consume_redir()` (`parser_redir.c`): maps the operator token's type to
  `t_redir_type`, frees the (now-meaningless) operator node, then calls
  `take_word()` for the target and appends the new `t_redir` to the
  command's `redirs` list. Only fails on the `malloc` for the `t_redir`
  struct itself — by the time step 4 lets a redirection token through,
  its target is *already guaranteed* to be a `TOKEN_WORD`, so there's no
  grammar re-checking here, only allocation-failure handling.
- `parse_command()` (`parser.c`): walks tokens until a pipe or end of
  input, routing each token through `parse_token()` — a `TOKEN_WORD`
  becomes another word appended to `args` (via the existing
  `add_token_back`, which already handles "the new item is itself a
  pre-linked chain," reused unchanged from step 3); anything else is
  handed to `consume_redir()`. On any allocation failure, everything
  built so far for *this* command is freed, remaining tokens are freed too
  (they can no longer be handed anywhere), and `*tokens` is set `NULL` —
  this is treated as an invariant every caller relies on: **a `NULL`
  return from `parse_command()` always means `*tokens` has already been
  fully drained**, so nothing further up the call chain has to guess
  whether cleanup already happened.
- `parse()` (`parser.c`): calls `parse_command()` once, then for as long
  as tokens remain (guaranteed by step 4 to always be sitting on exactly
  one `TOKEN_PIPE` at that point — never re-checked, since step 4 already
  rejected every other possibility) frees that pipe token and parses the
  next command, linking it on. A failure partway just frees the commands
  already built (thanks to the invariant above, tokens are already handled)
  and returns `NULL`.
- No separate grammar validation happens inside the parser at all — step 4
  already guarantees the token stream is well-formed for every token type
  that currently exists, so `parse()` only has one real failure mode left:
  `malloc` returning `NULL`. Trusting that upstream guarantee instead of
  re-validating is deliberate (matches "don't add checks for scenarios
  that can't happen").
- Wiring in `shell_loop`: extracted into a new `process_line()` static
  helper (needed to keep `shell_loop` itself under Norminette's 25-line
  function limit once parsing was added) — tokenize, validate, and (on
  success) `parse()` the result, replacing the temporary
  `debug_print_tokens` from steps 3-4 with `debug_print_ast` (moved to its
  own new temporary file, `src/shell/debug_ast.c`, to keep `shell.c`
  itself under the function-count norm limit). Still scaffolding only —
  step 7 (execution) is what finally consumes the AST for real and deletes
  this print.
- Verified interactively with piped test lines: a simple command, a
  `cmd < file | cmd` pipeline (splits into two `t_cmd` nodes correctly), a
  redir-only command (`> out`), a redirection interleaved with arguments on
  both sides (`echo a b > out1 c >> out2` — args `a b c` collected
  correctly, both redirections captured in order, independent of where
  they sat among the words), a heredoc token pair, and the running
  multi-fragment example (`echo "Hello, "$USER'!'` — three joined fragments
  preserved intact in `args`, ready for step 6's expansion). Syntax-error
  lines from step 4 (`|`, `echo |`, `>`) were re-run in the same batch to
  confirm nothing regressed: `parse()` is correctly never reached for
  those. `valgrind --leak-check=full` over the whole batch: 0 definitely/
  indirectly/possibly lost (same readline-only "still reachable" bytes as
  every prior step).
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal`. (Two `TOO_MANY_LINES` errors
  surfaced during development — `shell_loop` and `parse_command` — both
  fixed by extracting a helper, `process_line` and `parse_token`
  respectively, rather than relaxing anything.)

Full walkthrough: `docs/STEP_05_EXPLAINED.md`.

### Step 6 — Expansion: env vars, $?, quote removal, word splitting (done)

Files: `src/expansion/expansion.c`, `src/expansion/expand_var.c`,
`src/expansion/expand_split.c`. Struct addition: `t_split` (an
implementation-detail accumulator for the splitting algorithm — see below)
in `inc/structs.h`. Header additions: `expand`, `expand_fragment`,
`expand_fragments`, `split_word` prototypes in `inc/minishell.h`; `env_get`
added to the existing `// env` block and implemented in `src/env/env.c`.

- Checked the subject again before writing anything: it requires exactly
  two expansions — `$` followed by a sequence of characters (a variable),
  and `$?` (last foreground exit status) — plus the quoting rule already
  partially implemented by the tokenizer (single quotes block everything,
  double quotes block everything except `$`). Word splitting itself isn't
  named explicitly, but it's the direct consequence of "take bash as
  reference" once unquoted `$VAR` expansion is in play — an unquoted
  variable whose value contains whitespace becomes multiple `argv` words
  in bash, and this project's own `PROGRESS.md` checklist already named
  it as in-scope for this step. Four things were deliberately left out and
  logged as Decisions #8-#11: `$$` (PID), positional parameters (`$1`...),
  word-splitting on redirection targets (and the "ambiguous redirect"
  error that comes with it in real bash), and exhaustive malloc-failure
  propagation through every small string-building helper (matching
  `friend_minishell`'s own level of rigor here, not steps 1-5's stricter
  one — see Decision #11 for the reasoning).
- **The core algorithm, in two passes per logical word** (a
  `join_next`-chained run of `t_token` fragments — the same unit `parser.c`
  already operates on):
  1. **Stage A — `expand_fragments()`** (`expand_var.c`): for every
     fragment that *isn't* single-quoted, replace its `value` in place with
     `expand_fragment()`'s result — a single left-to-right scan that
     copies literal characters through untouched and, on every `$`,
     dispatches to `dollar_replacement()` (exit status for `$?`, an
     `env_get()` lookup for `$NAME`, or a literal `$` if what follows isn't
     a valid identifier start). Single-quoted fragments are skipped
     entirely — untouched, per the subject's "prevent interpretation of
     metacharacters" rule for `'...'`.
  2. **Stage B — `split_word()`** (`expand_split.c`): walks the
     now-expanded fragment chain and decides, fragment by fragment,
     whether its (already-expanded) text gets glued onto the current
     output word whole (any quoted fragment — single or double, since
     quoting is exactly what suppresses splitting) or split on runs of
     space/tab (a bare fragment, since real whitespace can only appear
     inside a bare fragment's *expanded* value — literal whitespace in the
     original input already ended the token back at tokenize time). The
     tricky part, and the one genuinely bash-specific piece of logic here:
     a bare fragment's *leading* whitespace closes off whatever was
     already accumulated (even mid-word, e.g. `"pre"$X` where `$X` starts
     with a space correctly splits into `pre` and the rest), and its
     *trailing* whitespace closes off the chunk just added — but a chunk
     with *no* adjoining whitespace on one side stays open, ready to glue
     with whatever the next fragment contributes. This is what makes
     `"$X"$Y` (`X="a b"`, `Y="c d"`) correctly produce `a bc` and `d` — two
     words, not three — matching real bash exactly (verified against a
     live bash process with the same input, see below).
  3. A dedicated **`touched` flag** on the accumulator (bundled with it
     into the new `t_split` struct, since C can't return multiple values
     and passing four separate parameters here would blow past
     Norminette's parameter limit) distinguishes "nothing has been glued
     onto this word yet" from "an empty string was deliberately glued."
     This is what makes `echo $UNSET` produce **zero** arguments (the sole
     fragment is bare, unquoted, and expands to nothing — untouched, so
     nothing is emitted) while `echo ""` and `echo "$UNSET"` both still
     produce **one empty-string** argument (the fragment is quoted, so it
     always glues — and thus always emits — even when its content is
     empty). Both are real, distinct, correct bash behaviors.
- **Nice reuse**: `expand_cmd_args()` (`expansion.c`) walks `cmd->args`
  (a flat chain of however many logical words back-to-back) by calling
  `take_word()` — the exact same function `parser.c` uses to detach one
  word at a time from a token list — repeatedly until the chain is empty,
  running stages A and B on each word and appending the result to a brand
  new `cmd->args`. The same "detach one join_next-bounded word" concept
  from step 5 does double duty here, just applied to a different pipeline
  stage.
- **Redirection targets** (`expand_cmd_redirs()`, `expansion.c`) get stage
  A only, then a plain `join_word()` concatenates every fragment's
  (expanded) text into one final string, unsplit — per Decision #10. The
  result is wrapped back into a single-node `t_token` (so `t_redir.target`
  keeps its existing type, no struct change needed) and the original
  fragment chain is freed.
- Verified interactively, piping identical input through both this
  project's binary and a real `bash` process side by side: plain
  variables (`$HOME`), quoting (`"$HOME"` vs `'$HOME'`), an unset variable
  both bare and quoted (`$UNSET_VAR` vs `"$UNSET_VAR"`), greedy variable-
  name matching (`x$UNSET_VARy` — `UNSET_VARy` is the variable name, not
  `UNSET_VAR` followed by literal `y`), `$?` after a syntax error (reads
  back `2`, confirming the exit-status wiring from step 4 still flows
  through correctly), and the word-splitting/seam-gluing cases
  (`$TESTVAR`, `"$TESTVAR"`, `pre$TESTVAR`, `"pre"$TESTVAR"`, using a real
  multi-word environment variable passed in via `env TESTVAR="a b"
  ./minishell` since `export` doesn't exist until step 8) — every case's
  `argv`-level boundaries matched real bash exactly. Also confirmed a
  quoted redirection target with an embedded expansion
  (`> "$TESTVAR"/file`) becomes one unsplit filename (`a b/file`), per
  Decision #10. `valgrind --leak-check=full` over the whole batch: 0
  definitely/indirectly/possibly lost bytes.
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal`. (Two errors surfaced during
  development: a `FORBIDDEN_TYPEDEF` for defining `t_split` directly in
  `expand_split.c` — fixed by moving it to `inc/structs.h`, matching where
  every other struct in the project already lives — and a `TOO_MANY_LINES`
  on `split_bare`, fixed by factoring its glue-onto-accumulator step out
  into the small shared `glue()` helper rather than relaxing anything.)

Full walkthrough: `docs/STEP_06_EXPLAINED.md`.

### Step 7 — Execution engine (done)

Files: `src/execution/execute.c`, `path.c`, `exec_arrays.c`, `redirect.c`,
`heredoc.c`, `pipeline.c`, `child.c`, `wait_status.c`; `src/shell/
signals_exec.c` (new). Struct additions: `heredoc_expand`/`heredoc_fd` on
`t_redir`, new `t_pipeline` struct (`n_cmds`/`pipes`/`pids`), both in
`inc/structs.h`. The temporary `debug_print_ast`/`src/shell/debug_ast.c`
scaffolding carried since step 3 is finally deleted — `shell_loop` now
calls `execute(shell)` for real after `expand(shell)`.

- Checked the subject once more before writing anything: "search and
  launch the right executable (based on the `PATH` variable or using a
  relative or absolute path)", the four redirections plus pipes (already
  named in steps 4-5's own checks), and "handle ctrl-C, ctrl-D and ctrl-\
  which should behave like in bash" — the last one is squarely this
  step's concern too, since it's specifically about behavior *while a
  command is running*, not just at the prompt (step 2's territory).
  Builtins are explicitly step 8, so every command right now — even
  `echo`/`cd`/`pwd` — goes through `PATH` search and `execve` like any
  other program; `cd`/`export`/`unset`/`exit` correctly fail with "command
  not found" until step 8 intercepts them (verified below).
- **Pipeline plumbing** (`pipeline.c`): `build_pipeline` allocates one
  `t_pipeline` up front — a `pids` array sized to the command count and a
  flat `pipes` array of `2*(n-1)` fds, with every `pipe()` call made
  *before* any `fork()` (so a failed setup never happens mid-fork).
  `wire_pipes` computes, for pipeline position `idx`, which single fd (if
  any) becomes that command's stdin/stdout; `close_pipes` closes every fd
  in the flat array — called by **every** child (after its own two are
  already `dup2`'d, so closing the originals is safe) and, critically, by
  the **parent** too once all children exist, since holding even one
  spare write-end open in the long-lived shell process would mean the
  last command's reader never sees EOF.
- **PATH search** (`path.c`): a command containing `/` is checked directly
  with `access(F_OK)`/`access(X_OK)`; a bare name is searched across
  every `$PATH` entry. Distinguishes "not found anywhere" (127, "command
  not found") from "found but not executable" (126, "Permission denied")
  by checking `F_OK` before `X_OK` at each candidate — real bash makes
  this same distinction, verified directly rather than assumed.
- **`argv`/`envp` construction** (`exec_arrays.c`): `build_argv` walks the
  now fully-expanded `cmd->args` `t_token` chain into a `NULL`-terminated
  `char **`, reusing the token's `value` pointers directly (no copying —
  the child either `execve`s, replacing its whole memory image, or exits,
  so nothing here is ever freed and nothing needs to be); `build_envp`
  rebuilds `"KEY=VALUE"` strings fresh from `shell->env` on every command,
  rather than caching, so a later `export`/`unset` (step 8) is guaranteed
  to be reflected correctly with no staleness bugs to worry about.
- **Redirections** (`redirect.c`): applied in the order they appear on
  each command, each one `open`+`dup2`+`close`. Deliberately does **not**
  special-case "only the last same-direction redirect matters" — applying
  every one in sequence and `dup2`-ing each over the last automatically
  produces that exact behavior (and its side effects, like an earlier `>`
  in the same command still truncating its file) for free, matching bash
  without any extra logic.
- **Heredocs** (`heredoc.c`): resolved for the *entire* pipeline before
  any `fork()` (matching bash — heredocs are read once, up front,
  regardless of how many pipeline stages exist), buffered through a
  reused temp file rather than a pipe (Decision #13), each line optionally
  `$`-expanded per `heredoc_expand` (Decision #14) before being written.
- **Signals during execution** (`signals_exec.c`): before forking,
  `SIGINT`/`SIGQUIT` are set to `SIG_IGN` in the parent (so a terminal
  Ctrl-C/Ctrl-\ delivered to the whole foreground process group — parent
  and children share one group, no job-control/process-group code needed
  since nothing here creates a separate one — doesn't disturb the shell
  itself); each child resets both to `SIG_DFL` immediately after `fork()`,
  before anything else, so it dies/cores exactly like a normal foreground
  program would in bash. After all children are reaped, `init_signals()`
  restores the normal interactive prompt handlers. `wait_status.c`
  converts the *last* command's `wait()` status into `shell->exit_status`
  (`WEXITSTATUS`, or `128 + WTERMSIG` for a signal-killed command,
  matching bash's convention), printing a bare newline for a
  `SIGINT`-killed child or `Quit (core dumped)` for `SIGQUIT`, exactly
  like real bash does at that point.
- Two small, necessary retrofits to earlier "done" steps, both logged as
  Decision #14 and explained there: `t_redir` gained two fields, and
  step 5's `consume_redir`/step 6's `expand_cmd_redirs` needed one line
  each to populate them correctly — the same kind of honest
  found-during-the-next-step fix as the Makefile prerequisite bug from
  step 1.
- Verified extensively:
  - Piped smoke tests: `echo`/`echo -n` (via the real coreutils binaries,
    since no builtins exist yet), a `| wc -l` pipe, `>`/`>>`/`<` redirects
    (including reading back file contents to confirm truncate vs. append),
    a nonexistent command (127, confirmed via `$?` on the next line),
    heredocs with both an unquoted delimiter (`$HOME` expands inside the
    body) and a quoted one (`'EOF'` — stays literal), and a 3-stage
    pipeline (`echo a | cat | rev`).
  - **Real pty tests** (Python `pty.fork()`, same technique as step 2 —
    piped stdin has no controlling terminal, Ctrl-C never generates a
    real `SIGINT` without one): a `sleep 5` foreground command killed by
    Ctrl-C — shell survives, fresh prompt appears, `$?` correctly reads
    back `130` — run repeatedly, solid every time.
  - `valgrind --leak-check=full` over the full smoke-test batch (parent
    process only — children either `execve` or `exit`, so nothing in them
    is a leak in the traditional sense): 0 definitely/indirectly/possibly
    lost bytes.
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal`. Several errors surfaced and
  were fixed properly during development, most notably a whole-file
  function-declaration alignment rule in `minishell.h` that isn't
  per-block: Norminette expects **every** function prototype in the file
  to share one common tab-aligned column, computed from the single
  longest return-type name anywhere in the file (here, `t_pipeline` at 10
  characters, pushing the shared column from 8 to 12) — discovered by
  bisecting with a scratch header file until the exact rule was clear,
  rather than guessing indefinitely.
- One attempted feature was rolled back after real testing showed it
  unreliable: matching bash's exact "Ctrl-C aborts the whole heredoc"
  behavior. See Decision #16 for the full account — this is the one place
  in the project so far where "verify, don't assume" caught a feature
  that looked right in code but didn't hold up under a real pty, and it
  was deliberately simplified rather than shipped flaky.

Full walkthrough: `docs/STEP_07_EXPLAINED.md`.

### Step 8 — Builtins: echo, cd, pwd, export, unset, env, exit (done)

Files: `src/builtin_functions/builtins.c`, `builtin_utils.c`,
`builtin_echo.c`, `builtin_pwd.c`, `builtin_cd.c`, `builtin_env.c`,
`builtin_export.c`, `builtin_export_print.c`, `builtin_unset.c`,
`builtin_exit.c` (new directory, matching the layout `CLAUDE.md` already
named); `src/execution/standalone.c` (new); `src/env/env_mutate.c` (new —
`env_set`/`env_unset`, the two mutation operations builtins need that
step 1's `env.c` never had to provide). Struct addition: `t_shell.
should_exit`. `src/expansion/expansion.c` was also split (a second file,
`expand_redirs.c`, took `expand_cmd_redirs`/`join_word`) — explained in
Decision #23.

- Checked the subject once more, word for word, before writing anything:
  `echo` with `-n` only, `cd` with only a relative/absolute path, `pwd`/
  `export`/`unset`/`env`/`exit` all "with no options" (`env` also "no...
  arguments"). Nothing here says a *bare* `cd` (no path) or `exit`'s
  numeric-argument form are forbidden — those are core behaviors of the
  builtins themselves, not "options," so both are implemented; anything
  bash does *beyond* that (`cd -`, `~` anywhere, `export -p`/`-n`, `env
  VAR=val cmd`) is deliberately left out, per "anything not asked is not
  required."
- **The no-fork exception step 7 deferred** (Decision #17): `execute()`
  now checks, before doing anything pipeline-related, whether the AST is
  a single command (`!shell->ast->next`) whose name is one of the seven
  builtins (`is_builtin`, `builtins.c`) — if so, `run_standalone_builtin`
  (`standalone.c`) runs it directly in the shell's own process, no
  `fork()` at all, so `cd`/`export`/`unset`/`exit` can actually mutate
  `shell->env`/`shell->exit_status`/the process's own working directory.
  A builtin as part of a multi-stage pipeline still goes through the
  existing `fork()`-per-stage path from step 7 (`run_child`, `child.c`,
  gained one `is_builtin` check before the `resolve_executable` call) —
  verified below that this correctly gives it subshell semantics (zero
  effect on the parent shell), matching real bash.
- **Redirections on a standalone builtin** (Decision #18): since there's
  no child process to permanently `dup2` and then die, `run_standalone_
  builtin` saves the real `stdin`/`stdout` via `dup()` first, applies the
  command's redirections with the *exact same* `apply_redirs` step 7
  already built (entirely redirection-target-agnostic — it never needed
  to know whether a fork happened), runs the builtin, then `dup2`s the
  saved descriptors back and closes them — so `pwd > file` redirects
  correctly without leaving the interactive shell's own terminal I/O
  pointed at `file` afterward.
- **`exit`'s process-termination mechanism** required one new field,
  `t_shell.should_exit`: the builtin itself never calls the real `exit()`
  — it only sets `should_exit = 1` (and `exit_status`) and returns
  normally. `shell_loop` checks the flag after every `process_line` call
  and `break`s if set, falling through to the exact same `free_shell` +
  `return shell.exit_status` path `main()` already used for Ctrl-D. This
  matters for a `valgrind`-clean shutdown: calling `exit()` directly from
  deep inside a builtin would skip every bit of cleanup steps 1-7 already
  built and verified leak-free. For `exit` running inside a **forked**
  child instead (part of a pipeline), no special handling is needed at
  all — `run_child` already unconditionally does `exit(run_builtin(...))`
  for any builtin, and calling the real `exit()` there is *correct*,
  since that child process genuinely is done; `should_exit` being set on
  that child's own private copy of `t_shell` is simply irrelevant once
  the child's memory disappears.
- **`export`/`unset` identifier validation** (Decision #19) and **`export`
  with no arguments** (Decision #20, sorted `declare -x KEY="value"`
  output, via a small hand-written insertion sort since neither libft nor
  the allowed functions include a generic one) were checked against real
  bash directly rather than assumed correct from reading the code.
- **The export-assignment word-splitting fix** (Decision #23): confirmed
  with a live test that `export FOO=$TESTVAR` (`TESTVAR="a b"`) actually
  produced the wrong result — `FOO="a"` plus a stray bogus `b=""` — before
  fixing it, not just inferred from the architecture. The fix lives
  entirely in `expand_cmd_args`: when the command is `export` and a later
  argument looks like `NAME=...`, its fragments are joined whole (reusing
  `join_word`, promoted to non-static) instead of going through
  `split_word`. Re-verified afterward: `export FOO=$TESTVAR` now correctly
  produces one `FOO="a b"`.
- `cd` updates `PWD`/`OLDPWD` via the new `env_set` (reads the *old*
  `getcwd()` before `chdir()`, the *new* one after) — checked this is
  real, expected `cd` behavior (not an optional extra) since bash always
  does it and other tools/prompts commonly depend on `PWD` being current.
- Verified extensively, checking actual behavior rather than assuming:
  `echo`/`echo -n`/`echo -nnn` (the repeated-`n` bash quirk, confirmed
  intentional, not guessed), `pwd`, `cd` (relative and absolute, `PWD`/
  `OLDPWD` correctly visible afterward via `export`'s own listing),
  `export` (bare assignment, print-all sorted, bare-name-only, invalid
  identifier), `unset` (valid and invalid names), `env`, and all three
  `exit` argument cases (`exit`, `exit N`, `exit N garbage`, `exit abc`) —
  confirmed both the printed messages/exit codes *and* the real process
  exit code via `$?` in the invoking shell. Confirmed a builtin inside a
  pipe (`export X=1 | true`, `cd /tmp | true`) has zero effect on the
  parent shell, correct subshell semantics. `valgrind --leak-check=full`
  over the whole battery, including the `exit N` shutdown path itself: 0
  definitely/indirectly/possibly lost bytes.
- `norminette src inc`: all files `OK`, only the expected
  `GLOBAL_VAR_DETECTED` notice on `g_signal`. Three `TOO_MANY_LINES`
  errors surfaced (`env_set`, `builtin_cd`, `builtin_exit`) and were fixed
  by extracting helpers (`env_append_new`, `update_pwd`,
  `non_numeric_exit` respectively), not by relaxing anything; the
  `expansion.c` split (Decision #23) was needed to stay under the
  5-functions-per-file limit once the export fix added a function there.

Full walkthrough: `docs/STEP_08_EXPLAINED.md`.

## Where we stopped / next step

Explained step 8 to the user in detail (the no-fork-for-a-standalone-
builtin exception and why it applies uniformly to all seven, the
save/restore-fds mechanism for a builtin's own redirections, the
`should_exit` flag and why `exit` can't just call the real `exit()`
directly, and the export-assignment word-splitting bug that was found and
fixed rather than left as a stale forward-note). Waiting for confirmation
before starting **Step 9: Bonus — && || with parentheses**.

Next concrete action when resuming: this is the point Decision #6 (back
in step 5) flagged as the natural place to introduce real branching —
`&&`/`||`/`(`/`)` need new `t_token_type` variants (tokenizer), grammar
rules for parentheses and logical-operator precedence (validation and
parser), and, since the mandatory part's flat `t_cmd` pipeline list is no
longer sufficient once branching exists, a real tree structure (pipelines
as leaves, `AND`/`OR` as internal nodes, parens as grouping) — the
`t_node`-shaped extension `friend_minishell` built from the start, now
finally warranted. Per the subject, this bonus is only evaluated at all
if the mandatory part (steps 1-8) is "fully implemented and functions
without any issues" — worth a full regression pass across every prior
step's test cases before starting, not just picking up where step 8 left
off.

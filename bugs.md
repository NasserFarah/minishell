# Minishell — Mandatory Part Bug Audit

Checked against: the evaluation sheet (`minishell_evalsheet.pdf`, fully
read), standard 42 Norm (via `norminette`), and the allowed-function
whitelist you provided (no local `subject.pdf` was available). Verified
with `norminette` (whole tree), a full 646-case run of the differential
suite under `valgrind --leak-check=full` (`tests/run_tests.sh`, diffs
against real bash), `tester.sh` (a from-scratch mandatory-part runner
mirroring the eval sheet section by section), `tests/pty/signal_tests.py`,
40+ direct exit-code comparisons against live bash covering every builtin
and every syntax-error/overflow/signal boundary case, and a direct code
read of every builtin and the parser/expansion core. Everything below was
reproduced against the current build (commit `5fa66d0` + the `$$` feature,
the `$_` fix, and the `get_next_line()` leak fix added after it).

---

## Open bugs

### Makefile: editing a `libft` source and running plain `make` does nothing

```
$ touch libft/ft_strlen.c && make
make: Nothing to be done for 'all'.   # libft.a and minishell stay stale
$ make -C libft                        # this alone rebuilds correctly
```

The top-level `$(LIBFT):` rule has no prerequisites, so `make` never
re-enters `libft/` once `libft/libft.a` exists — it can't tell the file is
stale. `libft/`'s own Makefile tracks dependencies correctly; the bug is
purely in how the top level calls it. Re-confirmed still present this pass.

- Fix: mark `$(LIBFT)` (or a dedicated recursive target) `.PHONY` so the
  recipe always re-enters `libft/` and lets its own Makefile decide whether
  anything needs rebuilding. Doesn't reintroduce "must not re-link" —
  `libft.a`'s mtime, and therefore whether the final link step re-runs,
  still only changes when libft actually had something to rebuild.

---

## Fixed this session

- **Unterminated quote didn't set `$?`.** `echo "unterminated` printed the
  right error but left `$?` unchanged instead of `2`. Fixed by threading
  the `error` flag `make_word_token()` already computed up through
  `tokenize()` to `process_line()`, which couldn't previously tell a real
  tokenizing error apart from a harmless blank line (both returned `NULL`).
- **`cd`'s "too many arguments" error said `bash:` instead of
  `minishell:`** — the only hardcoded wrong-shell-name string in the
  codebase.
- **Ambiguous redirect not detected.** `>$VAR` where `$VAR` expands to
  multiple unquoted words silently wrote to a file with a space in its
  name instead of erroring like bash's `ambiguous redirect`. Fixed by
  field-splitting the expanded target and rejecting non-single-field
  results before `open()`.
- **`cd` error messages never included the target path** (`cd: Not a
  directory` instead of bash's `cd: Makefile: Not a directory`). Also
  fixed: `cd` with `HOME` set-but-empty now no-ops instead of erroring.
- **`exit` silently wrapped on 19+ digit numeric overflow** instead of
  erroring — the guard was a pure digit-count threshold that can't
  distinguish `INT64_MAX` (valid) from `INT64_MAX+1` (both 19 digits).
  Also fixed a missing `return` that let the wrapped garbage value
  overwrite the correct error status even once overflow *was* detected.
- **`PATH` resolution matched directories, not just executable files.** An
  empty command word (`""`, `''`) or `.`/`..` could resolve to a real
  directory in `PATH`, giving exit 126 "Is a directory" instead of bash's
  127 "command not found". Fixed with `stat()` + `S_ISREG`.
- **`env` required `PATH` to exist before printing anything** — under
  `env -i`, it printed a fabricated error and silently dropped every other
  variable, even ones that were set.
- **`shell.c` called three unauthorized readline functions on shutdown**
  (`clear_history()`, `rl_free_line_state()`, `rl_cleanup_after_signal()`)
  — none are in the allowed-function list. Trimmed to the whitelisted
  `rl_clear_history()`.
- **`$_` didn't match bash in two ways.** The core "last argument of the
  previous simple command (or the command name if it had none)" logic was
  *already correct* (verified live against bash for `echo`, `ls`, `env`,
  `true`, `cd`) — an earlier note in this file wrongly flagged that part as
  broken based on a flawed test (`env | grep _=`, which tests a completely
  different bash mechanism: the `_` bash auto-injects into a *child
  process's* environment at `execve` time, unrelated to the shell's own
  `$_` parameter). The two real gaps: (1) bash does not update `$_` at all
  across a multi-stage pipeline (each stage runs in a subshell, and
  subshell variable changes never propagate back) — `get_last_last_arg()`
  updated it from the pipeline's last stage regardless; fixed by only
  computing a value when `shell->pipeline->next == NULL` (a single
  command). (2) bash sets `$_` at shell startup to its own invocation path
  — minishell just passively inherited whatever `_` happened to already be
  in its environment; fixed by explicitly setting it to `argv[0]` in
  `main.c`. Verified against bash for all three cases (single command,
  pipeline-leaves-it-untouched, startup value) — all now match.
- **`get_next_line()` left 1 byte "still reachable" at exit, every run.**
  This was previously misdocumented in this file as "readline-internal" —
  it was never actually verified against a real backtrace until now.
  Root cause: `get_next_line()`'s `static char *line` buffer persists
  between calls by design (to carry over partial data for the next read on
  the same fd), and nothing ever made one final call to drain it to `NULL`
  before the shell exits — not heredoc-specific, this hits *any* exit path
  through `get_next_line()`, including the plain non-interactive command
  reader in `shell_input.c`. Confirmed by isolating it: a pure interactive
  (readline-only, `get_next_line()` never touched) session showed the
  *real* readline-internal reachable memory instead — ~208KB across 222
  blocks, exactly matching what `readline.supp` suppresses — proving the
  1-byte item was a separate, distinct allocation the whole time. Fixed
  with a `fd == -1` sentinel case in `get_next_line()` that frees and nulls
  the static buffer, called once from `free_shell()` at shutdown. Verified:
  `valgrind` now reports "in use at exit: 0 bytes in 0 blocks — All heap
  blocks were freed, no leaks are possible" — not just 0 lost, genuinely
  zero bytes reachable, across no-heredoc and heredoc sessions alike.

---

## New feature: `$$`

Implemented the same way `$?` is — a special case in `dollar_replacement()`
(`expand_var.c`), checked before the general variable-name path. Since
`getpid()` is **not** on the allowed-function list, the PID comes from
reading `/proc/self/stat` (first field, before the first space) with only
`open()`/`read()`/`close()`, all of which are allowed. Split into a new
`expand_var_utils.c` (mirroring the existing `tilde.c`/`tilde_utils.c`
pattern) to stay under the norm's 5-functions-per-file and 25-lines-per-
function caps. Verified: expands to the actual process PID (checked
against the real forked PID directly), stable across repeated use in one
session, correctly literal inside single quotes, correctly expands inside
double quotes, and clean under valgrind including through heredoc bodies,
redirect targets, and `export`.

---

## Checked clean

- **Norm**: 100% — `norminette` reports `OK!` on every file in `src/`,
  `inc/`, `libft/`.
- **Build**: clean with `-Wall -Wextra -Werror`, no warnings, no relink on
  a no-op `make`.
- **Forbidden functions / globals**: nothing outside the allowed-function
  list anywhere in `src/`; exactly one global (`g_signal`, intentional).
- **Leaks**: genuinely zero — `valgrind` reports "in use at exit: 0 bytes
  in 0 blocks, all heap blocks were freed, no leaks are possible" after
  the `get_next_line()` fix above (previously 1 byte "still reachable",
  misattributed to readline in an earlier draft of this file). A full run
  of all 646 differential-suite cases under valgrind produced 0 leak/
  valgrind-error failures.
- **Exit codes**: 40+ direct comparisons against live bash across every
  builtin, every syntax-error path, and the `INT64_MAX`/`INT64_MIN`
  overflow boundaries in both directions — all match exactly.
- **Signals**: 7/7 automated pty tests pass (Ctrl-C/Ctrl-\/Ctrl-D in every
  required state, nested-shell exit-code propagation), plus manual pty
  checks (Ctrl-D closing a blocking `cat`'s stdin, heredoc bodies not
  polluting shell history).
- **`tester.sh`** (one case per mandatory eval-sheet item, now including
  dedicated `$_` coverage): 77/77 run (9 skipped, need a real terminal).
- **Direct code review** of every builtin, `env_mutate.c`, `parser.c`, and
  `expansion.c`: `is_valid_name()` correctly stops at `=` so `export
  FOO=bar` validates just `FOO`; `env_set`/`env_unset`/`env_append_new`
  are all correct; `ft_strduplicate(NULL)` is safe (used for "declared but
  unset" `export FOO`); `builtin_echo.c`'s flag parsing correctly rejects
  malformed flags like `-n-n`. One hygiene note, not a bug: `builtin_
  unset.c` has a large commented-out block above the active
  implementation — the active version (no identifier validation) is
  actually the *correct* one, matching real bash's `unset` behavior, so
  nothing to fix functionally, just dead code worth deleting for
  cleanliness before defense.
- **`env`/`export`/`unset` differential category** (157 cases, ~55-57
  "failures" this pass): almost all are a **test-harness artifact, not a
  bug** — bash rebuilds the environment array it hands to child processes
  from its own internal hash table, independent of inheritance order, so a
  live `bash -c env` oracle can never byte-for-byte match minishell's
  (correct) insertion-order-preserving `env`. A further slice of this
  noise is specifically `_`: the differential suite invokes both shells
  through `timeout`, and what `$_` starts out as depends on details of
  that invocation chain (see the `$_` fix above) that have nothing to do
  with whether minishell's logic is correct — `tester.sh` strips this one
  line before comparing for exactly this reason and has dedicated,
  reliable `$_` test cases instead.
- Everything else in the differential suite's remaining failures: bonus
  syntax not implemented (`&&`, `||`, `;`, `()`, wildcards, `<<<`,
  `$"..."`/`$'...'`, `+=`, backslash escaping, `2>&1`-style fd-duplication
  redirects) — intentionally out of scope since only the mandatory part
  was built, and none of it crashes the shell.
- **`pwd` after the current directory is deleted out from under the
  shell** diverges from bash (`getcwd()` fails and errors, vs. bash's
  cached-`$PWD` fallback) — real but very low priority, not part of the
  eval sheet's `pwd` checklist item.
- **Terminal resize (`SIGWINCH`)** can garble the prompt redisplay — a
  known upstream bug in the installed `libreadline 8.1.2` itself, not
  fixable from student code given the allowed-function list.

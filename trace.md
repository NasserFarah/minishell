# The Life of `echo "Hi"`

A step-by-step trace of what this minishell does, from the moment the user
types `echo "Hi"` at the prompt to the moment the prompt reappears.

## 0. Entry point

`main()` (`src/main/main.c:23`) builds the shell environment once at startup:

```c
init_shell(&shell, envp);   // shell.env = env_init(envp), exit_status = 0, ...
init_signals();
shell_loop(&shell);
```

`shell_loop()` (`src/shell/shell.c:38`) then loops forever calling
`readline("minishell$ ")`. The user types:

```
minishell$ echo "Hi"
```

`readline` returns the heap string `line = "echo \"Hi\""` and, since it's
non-empty, it's pushed into history with `add_history(line)`. Control passes
to `process_line(shell, line)`.

## 1. Tokenizing (`tokenize`, `src/tokenizer/tokenizer.c:68`)

`tokenize()` walks the raw line character by character:

- `skip_spaces` — no leading spaces here.
- `e` is not an operator char (`|<>`), so `make_word_token` is called via
  `next_token` → builds the bare segment `"echo"` (`tokenizer_word.c:52`)
  until it hits the space. Result: one `TOKEN_WORD` token, `value = "echo"`.
- `skip_spaces` eats the space between `echo` and `"Hi"`.
- `"` is a quote char, so `parse_quoted_segment` (`tokenizer_word.c:26`)
  runs: it records `quote = '"'`, scans until the matching `"`, and builds
  `ft_substr(line, start, len)` → `value = "Hi"`. Because the quote was `"`,
  the token gets `double_quoted = 1` (a `'` would instead set
  `single_quoted = 1`).

The result is a linked list of two `t_token`:

```
[ TOKEN_WORD "echo" ] -> [ TOKEN_WORD "Hi" (double_quoted=1) ] -> NULL
```

This list is stored in `shell->tokens`.

## 2. Validating (`validate_tokens`, `src/tokenizer/tokenizer_validate.c`)

`validate_pipes` and `validate_redirs` walk the list looking for stray `|`
or dangling redirection operators (`<`, `>`, `>>`, `<<`). Neither token is
a pipe or a redirect, so both checks pass trivially and `process_line`
proceeds to `parse`.

## 3. Parsing (`parse`, `src/parser/parser.c:59`)

`parse_command` consumes tokens until a `TOKEN_PIPE` or the list ends.
Each `TOKEN_WORD` is peeled off with `take_word` and appended to
`cmd->args` (`parser.c:24-32`). Since there's no `|`, `parse_command`
returns a single `t_cmd`:

```
t_cmd {
  args   = [ "echo" ] -> [ "Hi" (double_quoted) ] -> NULL
  redirs = NULL
  next   = NULL
}
```

`shell->pipeline` now points at this single-command pipeline, and
`shell->tokens` has been fully consumed (freed as it's walked).

## 4. Expansion (`expand`, `src/expansion/expansion.c:45`)

For each command in the pipeline, `expand_cmd_args` runs:

1. **Variable expansion** — `expand_fragments` (`expand_var.c:79`) is
   applied to every arg word *unless* it's single-quoted. `"Hi"` is
   double-quoted, not single-quoted, so it passes through
   `expand_fragment`, which scans for `$`. There is none, so the string
   comes back unchanged: `"Hi"`. (`"echo"` has no quotes at all, so it's
   expanded too, trivially unchanged.)
2. **Word splitting** — `split_word` (`expand_split.c:66`) decides whether
   the (now variable-expanded) text should be split on whitespace. Because
   the `"Hi"` token carries `double_quoted = 1`, `split_word` takes the
   `glue()` branch instead of `split_bare()` — quoted text is never
   word-split, even if it contained spaces. `"echo"` is bare/unquoted, so
   it goes through `split_bare`, which finds no internal whitespace and
   emits it as a single word.
3. The export-assignment special case (`is_assignment_word`) doesn't apply
   — `cmd->args` starts with `"echo"`, not `"export"`.

After expansion, `cmd->args` is rebuilt as a fresh token list:

```
[ "echo" ] -> [ "Hi" ] -> NULL
```

`expand_cmd_redirs` also runs but there are no redirections on this
command, so it's a no-op.

## 5. Execution dispatch (`execute`, `src/execution/execute.c:74`)

`execute()` first calls `resolve_heredocs(shell)` — no `<<` here, so
nothing happens. Then it checks the fast path:

```c
if (shell->pipeline->args && !shell->pipeline->next
    && is_builtin(shell->pipeline->args->value))
```

- `shell->pipeline->args` is non-NULL (`"echo"`).
- `shell->pipeline->next` is NULL — single command, no pipe.
- `is_builtin("echo")` (`builtins.c:15`) matches the first branch
  (`ft_strncmp(name, "echo", 5) == 0`) → true.

All three conditions hold, so **no `fork()` happens**. `echo` runs
in-process as a "standalone builtin":

```c
shell->exit_status = run_standalone_builtin(shell->pipeline, shell);
close_heredoc_fds(shell->pipeline);
return;
```

This is the key optimization/requirement in this shell: a lone builtin
with no pipe runs directly in the parent shell process (so `cd`, `export`,
`unset`, `exit` can actually mutate the shell's own state). `echo` doesn't
need that, but it takes the same path since it's still a single builtin
command.

## 6. Standalone builtin wrapper (`run_standalone_builtin`, `src/execution/standalone.c:26`)

```c
saved_in  = dup(STDIN_FILENO);
saved_out = dup(STDOUT_FILENO);
if (apply_redirs(cmd->redirs) == -1)
    status = 1;
else
    status = run_builtin(cmd, shell);
restore_fd(STDIN_FILENO, saved_in);
restore_fd(STDOUT_FILENO, saved_out);
```

`cmd->redirs` is NULL (no `>`, `>>`, `<` in this command), so
`apply_redirs` (`redirect.c:48`) loops zero times and returns `0`
immediately — stdin/stdout stay exactly as they are (the terminal).
`saved_in`/`saved_out` exist purely so a redirected builtin (e.g.
`echo "Hi" > file`) can have its fds restored afterward; here they're
just spare dup'd fds that get closed again by `restore_fd`.

## 7. Builtin dispatch (`run_builtin`, `src/builtin_functions/builtins.c:26`)

```c
name = cmd->args->value;   // "echo"
if (ft_strncmp(name, "echo", 5) == 0)
    return (builtin_echo(cmd, shell));
```

Matches the first branch → calls `builtin_echo(cmd, shell)`.

## 8. `builtin_echo` (`src/builtin_functions/builtin_echo.c:27`)

```c
arg = cmd->args->next;   // skip "echo" itself, arg -> "Hi"
newline = 1;
while (arg && is_echo_n_flag(arg->value))   // "Hi" is not "-n"/"-nnn...", skip
    ...
while (arg)
{
    ft_putstr_fd(arg->value, STDOUT_FILENO);  // writes "Hi"
    if (arg->next)                            // no next arg
        ft_putchar_fd(' ', STDOUT_FILENO);
    arg = arg->next;                          // arg = NULL, loop ends
}
if (newline)
    ft_putchar_fd('\n', STDOUT_FILENO);       // writes "\n"
return (0);
```

Output written to the terminal:

```
Hi
```

`builtin_echo` returns `0` — this is the command's exit status.

## 9. Unwinding

- `run_builtin` → returns `0` up to `run_standalone_builtin`.
- `run_standalone_builtin` restores the (unchanged) stdin/stdout fds and
  returns `0`.
- `execute()` sets `shell->exit_status = 0`, closes any heredoc fds
  (none), and returns.
- Back in `process_line` (`shell.c:15`): `free_cmd(shell->pipeline)` frees
  the `t_cmd`/`t_token` list built during parsing/expansion;
  `shell->pipeline = NULL`.
- Back in `shell_loop`: `shell->should_exit` is still `0`, so the loop
  continues, `line` was already freed right after tokenizing
  (`shell.c:18`), and `readline("minishell$ ")` is called again, printing
  a fresh prompt.

## Summary — call chain

```
main
 └─ shell_loop
     └─ process_line
         ├─ tokenize                    "echo \"Hi\""  ->  [echo] [Hi(dq)]
         ├─ validate_tokens             OK (no pipes/redirs to check)
         ├─ parse                        -> t_cmd{args:[echo,Hi], redirs:NULL}
         ├─ expand
         │   ├─ expand_cmd_args
         │   │   ├─ expand_fragments     ($-expansion; none present)
         │   │   └─ split_word           (double-quoted "Hi" kept intact)
         │   └─ expand_cmd_redirs        (no-op, no redirs)
         └─ execute
             └─ (single builtin, no pipe -> no fork)
                 run_standalone_builtin
                     ├─ apply_redirs      (no-op, redirs = NULL)
                     └─ run_builtin
                         └─ builtin_echo  writes "Hi\n" to STDOUT_FILENO
```

No child process is ever created for this particular command — that only
happens for external binaries or any command that's part of a multi-stage
pipeline (see `fork_cmd`/`run_child` in `src/execution/execute.c` and
`src/execution/child.c`).

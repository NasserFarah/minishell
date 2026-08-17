# Step 8 — Line-by-line explanation

Covers **Step 8 — Builtins: echo, cd, pwd, export, unset, env, exit**, per
`PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/structs.h` (one new field) -> `inc/minishell.h` (new declarations) ->
`src/env/env_mutate.c` (the two mutation operations builtins need) ->
`src/builtin_functions/builtins.c` (the dispatcher) -> the seven
individual builtin files -> `src/execution/standalone.c` (the no-fork
exception) -> `src/execution/execute.c` + `child.c` (wiring the dispatcher
into both the fork and no-fork paths) -> `src/shell/shell.c` (the
`should_exit` flag) -> `src/expansion/expansion.c` +
`expand_redirs.c` (the export word-splitting fix, and why it lives here).

---

## 0. What the subject actually requires here (checked first)

Re-read `en.subject.pdf`, word for word, before writing anything:

> `echo` with option `-n`
> `cd` with only a relative or absolute path
> `pwd` with no options
> `export` with no options
> `unset` with no options
> `env` with no options or arguments
> `exit` with no options

Every one of these describes what to **leave out** (`-e`/`-E` on `echo`,
`cd -`/`~` handling, `export -p`/`-n`/`-f`, `env VAR=val cmd`), not what to
leave *in*. A bare `cd` (no path) going to `$HOME`, and `exit N` taking a
numeric exit code, are core parts of what these commands *are* in bash —
neither is an "option" — so both are implemented; everything else bash
does beyond the bare command is deliberately absent, matching every
earlier step's "anything not asked is not required."

Two forward-pointers from earlier steps get resolved here, and both are
worth being honest about rather than silently fixing without comment:
- Step 7's Decision #12 explicitly named "a builtin that doesn't fork"
  as *this* step's job.
- Step 6/7 flagged, but did not implement, an `export`-specific
  word-splitting exemption. This step actually **verified the bug exists**
  (see section 7) before fixing it, rather than assuming the earlier
  note was still accurate.

---

## 1. `inc/structs.h` — one new field

```c
typedef struct s_shell
{
	t_env	*env;
	int		exit_status;
	int		interactive;
	int		should_exit;
	t_token	*tokens;
	t_cmd	*pipeline;
}	t_shell;
```
`should_exit` is set **only** by the `exit` builtin, and **only** matters
when `exit` runs in the shell's own process (the no-fork, standalone
case) — see section 6 for exactly why this indirection exists instead of
just calling the real `exit()`.

---

## 2. `src/env/env_mutate.c` — the two mutations builtins need

`env.c` (step 1) only ever built the list once at startup and read it —
nothing in it could add, update, or remove an entry. Two new functions:

```c
static void	env_append_new(t_env **env, const char *key, const char *value)
{
	...
}

void	env_set(t_env **env, const char *key, const char *value)
{
	t_env	*cur;

	cur = *env;
	while (cur)
	{
		if (cur->key && ft_strncmp(cur->key, key, ft_strlen(key) + 1) == 0)
		{
			free(cur->value);
			cur->value = ft_strdup(value);
			return ;
		}
		cur = cur->next;
	}
	env_append_new(env, key, value);
}
```
Update-in-place if the key already exists; otherwise append a new node
(`env_append_new`, factored out purely to keep `env_set` under
Norminette's 25-line limit — a real `TOO_MANY_LINES` error surfaced here
during development). Both `cd` (for `PWD`/`OLDPWD`) and `export` (for
`NAME=value`) go through this one function.

```c
void	env_unset(t_env **env, const char *key)
{
	t_env	*cur;
	t_env	*prev;

	cur = *env;
	prev = NULL;
	while (cur)
	{
		if (cur->key && ft_strncmp(cur->key, key, ft_strlen(key) + 1) == 0)
		{
			if (prev)
				prev->next = cur->next;
			else
				*env = cur->next;
			free(cur->key);
			free(cur->value);
			free(cur);
			return ;
		}
		prev = cur;
		cur = cur->next;
	}
}
```
Standard singly-linked-list removal, tracking `prev` so the fix-up works
whether the match is the head node (`*env = cur->next`) or anywhere else
(`prev->next = cur->next`) — the reason this needs `t_env **`, not
`t_env *`: only the caller's actual `shell->env` field can have its head
pointer reassigned through a double pointer.

Deliberately **not** touched: `env.c` itself, or its `new_env_node`/
`env_add_back` helpers. `env_set`'s "append" branch duplicates a few lines
of list-append logic rather than reusing those (they're `static` and
private to `env.c`) — a small, contained duplication was judged lower-risk
than reopening and re-verifying a step-1 file that's been solid since.

---

## 3. `src/builtin_functions/builtins.c` — the dispatcher

```c
int	is_builtin(const char *name)
{
	return (ft_strncmp(name, "echo", 5) == 0
		|| ft_strncmp(name, "cd", 3) == 0
		|| ft_strncmp(name, "pwd", 4) == 0
		|| ft_strncmp(name, "export", 7) == 0
		|| ft_strncmp(name, "unset", 6) == 0
		|| ft_strncmp(name, "env", 4) == 0
		|| ft_strncmp(name, "exit", 5) == 0);
}
```
Each comparison uses `ft_strncmp(name, "literal", len_of_literal + 1)` —
the same "compare through the terminator too" trick `env_get` (step 6)
already established for exact (not prefix) matching, just with the length
known at compile time here instead of computed via `ft_strlen`.

```c
int	run_builtin(t_cmd *cmd, t_shell *shell)
{
	char	*name;

	name = cmd->args->value;
	if (ft_strncmp(name, "echo", 5) == 0)
		return (builtin_echo(cmd, shell));
	...
	return (builtin_exit(cmd, shell));
}
```
A plain comparison chain, not a function-pointer lookup table — seven
fixed, known cases don't need the extra indirection a table would add,
and a chain is simpler to read. Every builtin function shares the exact
same signature (`t_cmd *cmd, t_shell *shell`) purely for this dispatcher's
uniformity, even though most of them only need one or the other (`echo`
needs neither, technically — see section 4).

`is_builtin` is called from two different places for two different
reasons: `execute()` (section 5) uses it to decide whether to skip
forking entirely; `run_child()` (section 5) uses it, *inside* an already
-forked child, to decide whether to run the builtin logic directly
instead of searching `PATH` and calling `execve`.

---

## 4. The seven builtins, briefly

**`builtin_echo.c`** — the one wrinkle is `-n`'s repeatability:
```c
static int	is_echo_n_flag(const char *s)
{
	if (s[0] != '-' || s[1] != 'n')
		return (0);
	i = 1;
	while (s[i] == 'n')
		i++;
	return (s[i] == '\0');
}
```
`-n`, `-nn`, `-nnnnn` — anything that's a dash followed by *only* `n`
characters — all count as the flag, matching real bash's own `echo`
builtin exactly (checked directly, not guessed); anything with an `e` or
other character after the dash (`-ne`, `-x`) does not match and is treated
as a normal argument instead, since only `-n` is asked for.

**`builtin_pwd.c`** — `getcwd` into a fixed 4096-byte buffer (the common
Linux `PATH_MAX`), erroring via `perror` if it fails.

**`builtin_env.c`** — walks `shell->env`, printing `KEY=value` for every
entry that has *both* a key and a value (skips the malformed-`envp`-entry
case from step 1, where `value` can legitimately be `NULL`) — matching
real bash's `env`, which also only lists variables that actually have a
value.

**`builtin_cd.c`**:
```c
static void	update_pwd(t_shell *shell, char *oldpwd)
{
	char	newpwd[4096];

	if (getcwd(newpwd, sizeof(newpwd)))
	{
		env_set(&shell->env, "OLDPWD", oldpwd);
		env_set(&shell->env, "PWD", newpwd);
	}
}

int	builtin_cd(t_cmd *cmd, t_shell *shell)
{
	char	*target;
	char	oldpwd[4096];

	if (cmd->args->next)
		target = cmd->args->next->value;
	else
		target = env_get(shell->env, "HOME");
	if (!target)
	{
		ft_putstr_fd("minishell: cd: HOME not set\n", STDERR_FILENO);
		return (1);
	}
	if (!getcwd(oldpwd, sizeof(oldpwd)))
		oldpwd[0] = '\0';
	if (chdir(target) == -1)
	{
		perror("minishell: cd");
		return (1);
	}
	update_pwd(shell, oldpwd);
	return (0);
}
```
`getcwd` runs *before* `chdir` (to capture what becomes `OLDPWD`) and
*after* (to capture the new `PWD`) — `update_pwd` was factored out purely
to keep `builtin_cd` under the 25-line limit (another real `TOO_MANY_
LINES` hit during development). No path given falls back to `$HOME`
(checked this is core `cd` behavior, not an optional extra); `$HOME`
itself being unset is reported the same way real bash reports it
("HOME not set").

**`builtin_export.c`** / **`builtin_export_print.c`**:
```c
static int	export_one(t_shell *shell, const char *arg)
{
	if (!is_valid_name(arg))
	{
		... "not a valid identifier" ...
		return (0);
	}
	eq = ft_strchr(arg, '=');
	if (eq)
	{
		name = ft_substr(arg, 0, eq - arg);
		env_set(&shell->env, name, eq + 1);
		free(name);
	}
	else if (!env_get(shell->env, arg))
		env_set(&shell->env, arg, "");
	return (1);
}
```
`is_valid_name` (`builtin_utils.c`, shared with `unset`) checks the
standard shell-identifier rule: must start with a letter or underscore,
then only letters/digits/underscores up to wherever `=` appears (or to
the end of the string, if there's no `=` at all — the same function
handles both the `NAME=value` and bare-`NAME` forms this way, since it
simply stops looking the moment it hits `=`). A bare `NAME` that's
genuinely new is created with an empty value (Decision #21 — this
project's `t_env` list doubles as both the shell's variable store *and*
the literal environment, so there's no separate "declared but not yet a
real env var" state to model the way real bash's own internal
distinction works; the simplification shows up as `NAME=` in `env`'s
output instead).

`export` with no arguments prints every variable, **sorted**, in bash's
own `declare -x KEY="value"` format — this exact format was checked
against real bash, not guessed:
```c
static int	key_cmp(const char *a, const char *b)
{
	while (*a && *a == *b)
	{
		a++;
		b++;
	}
	return ((unsigned char)*a - (unsigned char)*b);
}
```
A plain hand-written `strcmp` — libft has none, and this is the first
place the project has actually needed one. `sort_env` (an insertion-style
sort over an array of `t_env *` pointers, collected by `collect_env`) does
the ordering; neither libft nor the subject's allowed-functions list
includes a generic sort (no `qsort`), so a small hand-rolled one was the
only option, and for typical environment sizes (dozens of entries) its
`O(n²)` cost is irrelevant.

**`builtin_unset.c`** — the same `is_valid_name` check per argument,
`env_unset` for each valid one; an invalid name reports the error and
sets a `1` return status but doesn't stop processing the rest of the
arguments (matching bash, which also keeps going).

**`builtin_exit.c`** — covered fully in section 6, since its behavior is
intertwined with the `should_exit` mechanism.

---

## 5. Wiring the dispatcher into both execution paths

`src/execution/standalone.c` — the no-fork case (Decision #17-18):
```c
static int	save_fd(int fd)
{
	return (dup(fd));
}

static void	restore_fd(int fd, int saved)
{
	dup2(saved, fd);
	close(saved);
}

int	run_standalone_builtin(t_cmd *cmd, t_shell *shell)
{
	int	saved_in;
	int	saved_out;
	int	status;

	saved_in = save_fd(STDIN_FILENO);
	saved_out = save_fd(STDOUT_FILENO);
	if (apply_redirs(cmd->redirs) == -1)
		status = 1;
	else
		status = run_builtin(cmd, shell);
	restore_fd(STDIN_FILENO, saved_in);
	restore_fd(STDOUT_FILENO, saved_out);
	return (status);
}
```
`apply_redirs` — the exact same function step 7 wrote for a forked
child's redirections — is reused completely unchanged; it was never
written with any assumption about forking, so it works here for free.
What's new is saving the real `stdin`/`stdout` via `dup()` *before*
touching anything, and restoring them via `dup2` *after* the builtin
runs — necessary specifically because, unlike a forked child (which just
dies, taking its redirected descriptors with it), this code runs in the
shell's own long-lived process. Without the restore, `pwd > file` would
permanently leave the interactive shell's own output silently going to
`file` from then on.

`src/execution/execute.c` — deciding whether to take this path at all:
```c
void	execute(t_shell *shell)
{
	t_pipeline	*pl;

	resolve_heredocs(shell);
	if (shell->pipeline->args && !shell->pipeline->next
		&& is_builtin(shell->pipeline->args->value))
	{
		shell->exit_status = run_standalone_builtin(shell->pipeline, shell);
		close_heredoc_fds(shell->pipeline);
		return ;
	}
	pl = build_pipeline(count_cmds(shell->pipeline));
	...
```
Three conditions, all required: there's a command name at all (not a
redir-only stage), it's the *only* command in the pipeline (`!shell->pipeline
->next`), and that name is a builtin. Fail any one and execution falls
straight through to step 7's unchanged fork-per-stage path below.

`src/execution/child.c` — the piped case:
```c
if (!cmd->args)
	exit(0);
if (is_builtin(cmd->args->value))
	exit(run_builtin(cmd, shell));
path = resolve_executable(cmd->args->value, shell->env, &code);
```
One check added, right before the `PATH`-search path from step 7. A
builtin here still runs inside a normal forked child — meaning it gets
subshell semantics automatically, for free, from the exact same
process-isolation `fork()` already provides. `cd /tmp | true` chdir's
*that child's* copy of the process, which vanishes the instant the child
exits; the parent shell's real working directory is untouched. Verified
directly (see the end-to-end section) rather than just assumed from how
`fork()` is supposed to work.

---

## 6. `should_exit` — why `exit` can't just call the real `exit()`

This is the one piece of new *shell-level* state this step needed, and
the reasoning is worth spelling out. `builtin_exit` (`builtin_exit.c`):

```c
static int	non_numeric_exit(t_shell *shell, const char *arg)
{
	... "numeric argument required" ...
	shell->should_exit = 1;
	shell->exit_status = 255;
	return (255);
}

int	builtin_exit(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;

	ft_putendl_fd("exit", STDOUT_FILENO);
	arg = cmd->args->next;
	if (!arg)
	{
		shell->should_exit = 1;
		return (shell->exit_status);
	}
	if (arg->next)
	{
		... "too many arguments" ...
		return (1);
	}
	if (!is_numeric(arg->value))
		return (non_numeric_exit(shell, arg->value));
	shell->should_exit = 1;
	shell->exit_status = exit_code_mod256(arg->value);
	return (shell->exit_status);
}
```
Three bash-verified cases (Decision #22), not guessed: no argument keeps
`$?`; a single non-numeric argument prints an error but *still* exits,
with status `255`; two or more arguments prints a *different* error and
does **not** exit at all — `$?` becomes `1`, the shell just keeps
running. `exit_code_mod256` reduces an arbitrarily long digit string to
`0-255` one digit at a time under modular arithmetic
(`(val * 10 + digit) % 256`), so it can never overflow `int` regardless
of how many digits are typed — real bash's own `exit` wraps arbitrarily
large numbers the same way, this isn't a shortcut invented here.

`ft_putendl_fd("exit", ...)` prints unconditionally, matching this
project's own existing Ctrl-D handler in `shell.c` (step 1), which
already prints `"exit\n"` unconditionally too, regardless of
`shell->interactive` — kept consistent with that established precedent
rather than introducing a new conditional check only one of the two
"ways to exit" would have.

**Why `should_exit` exists instead of just calling the real `exit()`
here**: whichever context `builtin_exit` runs in determines what "exiting"
should even mean:
- Inside a **forked child** (`run_child`, part of a pipe): `exit(run_
  builtin(cmd, shell))` already unconditionally calls the real `exit()`
  right after, for *any* builtin, not just this one. `should_exit` being
  set on that child's own private `t_shell` copy is simply irrelevant —
  nothing ever reads it again before the child's memory disappears. The
  real `exit()` call happening here is *correct*: that one forked process
  genuinely is done, matching bash's own subshell-exits-the-subshell
  behavior for `exit` inside a pipe.
- Running **standalone**, no fork (`run_standalone_builtin`): there is no
  "exit(); the surrounding process was disposable anyway" — the
  surrounding process *is* the whole interactive shell. Calling the real
  `exit()` directly from inside a builtin, several call-frames deep,
  would skip every teardown step this project has built and
  `valgrind`-verified since step 1 (`free_shell`, freeing `shell->env`).
  So instead, `builtin_exit` just sets `should_exit` and returns
  normally, same as any other builtin. `shell_loop` (`shell.c`) checks the
  flag once, right after `process_line`:
  ```c
  process_line(shell, line);
  if (shell->should_exit)
  	break ;
  ```
  and falls out of its `while (1)` exactly the way Ctrl-D already does —
  `main()` then runs `free_shell` and returns `shell.exit_status`
  completely normally. Verified with `valgrind` specifically on the
  `exit N` shutdown path (not just the Ctrl-D one already covered by
  earlier steps): 0 leaks, confirming this indirection actually achieves
  what it's for.

---

## 7. The export word-splitting fix — verified before fixing

Steps 6 and 7 both left a note that `export NAME=$VAR` might not behave
correctly, since `expand_cmd_args` (step 6) had no way to know a command
was `export` and treat its assignment arguments specially. Rather than
just re-stating that note again, this step **checked it directly**:

```
$ env TESTVAR="a b" ./minishell
minishell$ export FOO=$TESTVAR
minishell$ export
declare -x FOO="a"
declare -x b=""
```

Confirmed: the bug was real. `FOO=$TESTVAR` is one bare token pre-
expansion (`$` doesn't end a bare token); after step 6's stage A, its
*value* becomes `"FOO=a b"` — correct so far — but stage B (`split_word`,
which has no idea this string is secretly a `NAME=value` pair) then
splits that whitespace exactly like it would for any other unquoted
expansion, producing two separate final words: `FOO=a` and a stray bare
`b`, which `export_one` then treats as an unrelated bare-name argument.

The fix, in `expand_cmd_args` (`expansion.c`):
```c
static int	is_assignment_word(t_token *word)
{
	return (ft_strchr(word->value, '=') && is_valid_name(word->value));
}

static void	expand_cmd_args(t_cmd *cmd, t_shell *shell)
{
	...
	is_export = old && ft_strncmp(old->value, "export", 7) == 0;
	while (old)
	{
		word = take_word(&old);
		expand_fragments(word, shell);
		if (is_export && new_args && is_assignment_word(word))
			add_token_back(&new_args, new_token(TOKEN_WORD, join_word(word)));
		else
			add_token_back(&new_args, split_word(word));
		free_tokens(word);
	}
	cmd->args = new_args;
}
```
`is_export` is computed once, from the very first word (the command name
itself) before the loop starts consuming anything. `new_args` being
non-`NULL` is what distinguishes "this is an argument *after* the command
name" from "this is the command name itself" — reusing state that already
existed rather than adding a separate counter. For a word that both is an
`export` argument *and* looks like `NAME=...` (checked with the same
`is_valid_name` `unset`/`export` already use elsewhere, up to the `=`),
its fragments are joined **whole** via `join_word` — the exact same
function `expand_cmd_redirs` already uses for redirection targets, which
never word-splits either, for the same underlying reason (an assignment
value, like a filename, is one indivisible thing, not a sequence of
separate shell words). Everything else still goes through `split_word`
exactly as before.

**Why `expansion.c` got split into two files this step**: adding
`is_assignment_word` pushed `expansion.c` to six functions, one over
Norminette's limit. Since `join_word` was needed in both this new
`export`-specific path *and* the pre-existing `expand_cmd_redirs`, and
`any_quoted` only serves `expand_cmd_redirs`, the natural split was to
move `expand_cmd_redirs`/`join_word`/`any_quoted` into a new file,
`expand_redirs.c` (`join_word` promoted from `static` to a normal
declared function, since it's now called from two separate files) —
leaving `expansion.c` with just `is_assignment_word`, `expand_cmd_args`,
and the public `expand` entry point.

Re-verified after the fix: `export FOO=$TESTVAR` now correctly produces
one `FOO="a b"`, no stray variable.

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `process_line`
-> `tokenize` -> `validate_tokens` -> `parse` -> `expand` (now
`export`-aware for assignment arguments) -> `execute`:
- if a single builtin: `run_standalone_builtin` (-> `apply_redirs` ->
  `run_builtin` -> one of the seven `builtin_*` functions, possibly
  mutating `shell->env` via `env_set`/`env_unset` or setting `shell->
  should_exit`) -> restore fds;
- otherwise, step 7's unchanged fork-per-stage path, where `run_child`
  now also checks `is_builtin` before falling back to `PATH` search.

-> back in `shell_loop`, check `shell->should_exit` and `break` if set ->
`free_cmd` -> loop back to `readline`, or (if `should_exit`) fall through
to `free_shell` + `return shell.exit_status` in `main`.

Verified extensively: every builtin's core behavior (including bash's
exact `-n`-repetition and three-case `exit` argument handling, checked
directly, not assumed), `PWD`/`OLDPWD` tracking across `cd`, subshell
isolation for a builtin inside a pipe, and the real, confirmed export
word-splitting bug found and fixed rather than left as a stale note.
`valgrind --leak-check=full` across the whole battery, including the
`exit N` shutdown path itself: 0 definitely/indirectly/possibly lost
bytes.

Every mandatory-part checklist item (steps 1-8) is now implemented.
**Step 9 (bonus: `&&`/`||` with parentheses)** is next, per `PROGRESS.md`
— gated, per the subject, on the mandatory part being fully working
first.

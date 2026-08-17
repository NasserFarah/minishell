# Step 7 — Line-by-line explanation

Covers **Step 7 — Execution engine**, per `PROGRESS.md`.

Files walked, in the order they're most naturally read:
`inc/structs.h` (new fields/types) -> `inc/minishell.h` (new declarations)
-> `src/execution/pipeline.c` (the plumbing everything else sits on) ->
`src/execution/path.c` (finding what to run) -> `src/execution/
exec_arrays.c` (building `execve`'s arguments) -> `src/execution/
redirect.c` (applying `<`/`>`/`>>`) -> `src/execution/heredoc.c` (`<<`) ->
`src/shell/signals_exec.c` (Ctrl-C/Ctrl-\ while a command runs) ->
`src/execution/child.c` (what one forked child actually does) ->
`src/execution/wait_status.c` (turning a wait status into `$?`) ->
`src/execution/execute.c` (the driver that ties all of the above together)
-> `src/shell/shell.c` (wiring, and deleting the scaffolding).

---

## 0. What the subject actually requires here (checked first)

Re-read `en.subject.pdf` before writing anything. This step is where most
of the subject's bullet points that had been *parsed* but not yet *acted
on* finally become real:

> Search and launch the right executable (based on the `PATH` variable or
> using a relative or an absolute path).
> Implement the following redirections: `<`... `>`... `<<` should be given
> a delimiter, then read the input until a line containing the delimiter
> is seen... `>>`...
> Implement pipes (`|`)... connected... via a pipe.
> Handle ctrl-C, ctrl-D and ctrl-\ which should behave like in bash...
> ctrl-C displays a new prompt on a new line... ctrl-\ does nothing.

Two things shaped everything below:
- Builtins (`echo`, `cd`, `pwd`, `export`, `unset`, `env`, `exit`) are
  explicitly **step 8**. So this step treats every command — even ones
  whose names happen to also be builtins — as something to `PATH`-search
  and `execve`. This is a deliberately incomplete but honest state: typing
  `cd` right now correctly prints "command not found", because there's
  really is no `cd` executable on most systems (it can't exist as one —
  changing directory only means something for the process itself). `echo`/
  `pwd`/`env` happen to also exist as real coreutils binaries, so those
  *appear* to work already, purely coincidentally.
- "Ctrl-C... should behave like in bash" isn't only about the prompt
  (that was step 2's job) — it's *at least as much* about what happens
  while a command is actually running, which didn't exist as a concept
  before this step. That's why the signal-handling additions here
  (`signals_exec.c`) belong to this step, not a bolt-on afterthought.

`friend_minishell/src/execution/` was not consulted for structure this
time — the fork/pipe/execve pattern here is standard POSIX shell
plumbing, not something with meaningful room for a "second opinion on
shape" the way the parser's tree-vs-list choice had.

---

## 1. `inc/structs.h` — what's new

```c
typedef struct s_redir
{
	t_redir_type	type;
	t_token			*target;
	int				heredoc_expand;
	int				heredoc_fd;
	struct s_redir	*next;
}	t_redir;
```
Two fields added to the struct step 5 already built. `heredoc_fd` starts
at `-1` (set in step 5's `consume_redir`) meaning "not a heredoc, or not
yet resolved" — this step's `resolve_heredocs` fills it in with a real,
readable fd before any child is forked. `heredoc_expand` starts at `1`
(also step 5) and is overwritten by step 6's `expand_cmd_redirs` — see
Decision #14 for why that specific split between "set a harmless default
in the parser" and "compute the real value in expansion" was necessary
(the parser doesn't have $-expansion machinery to know what "quoted"
even resolves to; expansion has it, but only briefly, before it flattens
the target chain).

```c
typedef struct s_pipeline
{
	int		n_cmds;
	int		*pipes;
	pid_t	*pids;
}	t_pipeline;
```
A new, purely implementation-detail bundle — not part of the shell's
persistent state (nothing here needs to survive past one `execute()`
call). It exists because C can't return multiple values and several
functions in this step need "the pipe fds" *and* "the pid array" *and*
"how many commands" together — bundling them avoids blowing past
Norminette's four-parameter limit on every function that touches pipeline
state, the same reasoning that produced `t_split` in step 6.

---

## 2. `inc/minishell.h` — new declarations

```c
void		signals_ignore_during_exec(void);
void		signals_child_default(void);
```
```c
void		execute(t_shell *shell);
char		*resolve_executable(const char *cmd, t_env *env, int *exit_code);
char		**build_argv(t_token *args);
char		**build_envp(t_env *env);
int			apply_redirs(t_redir *redirs);
void		resolve_heredocs(t_shell *shell);
void		close_heredoc_fds(t_cmd *pipeline);
t_pipeline	*build_pipeline(int n_cmds);
void		wire_pipes(t_pipeline *pl, int idx);
void		close_pipes(t_pipeline *pl);
void		free_pipeline(t_pipeline *pl);
void		run_child(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx);
int			wait_all(t_pipeline *pl);
```
Only `execute` is the module's real public API, called once from
`shell.c`. Everything else is cross-file internal, declared centrally per
the project's existing convention. `debug_print_pipeline`'s declaration —
present since step 5 — is now gone entirely, along with the file it
named (`src/shell/debug_pipeline.c`, deleted this step): the scaffolding every
prior step's log explicitly flagged as temporary is finally replaced by
real consumption of the AST.

**A Norminette detail worth recording**: getting this block to pass took
longer than expected, because Norminette's function-declaration alignment
check turned out to apply to the **entire file**, not per `//`-comment
block. Adding `t_pipeline *build_pipeline(...)` — at 10 characters, the
longest return-type name anywhere in the header — forced *every single
other* prototype in the file (all the way back to `// shell` at the top)
to be re-aligned to a shared column (12, the next tab-stop past 10),
each with however many tabs its own type name needs to reach that column
(`void`/`char` need two tabs, `int` needs three, `t_pipeline` needs one).
This was confirmed by bisecting with a disposable scratch header file
outside the project, rather than guessing — isolating single lines,
adding lines back one at a time, until the exact rule ("one shared column
for the whole file") was unambiguous.

---

## 3. `src/execution/pipeline.c` — the fork/pipe plumbing

```c
static t_pipeline	*pipeline_fail(t_pipeline *pl)
{
	if (pl)
	{
		free(pl->pids);
		free(pl->pipes);
		free(pl);
	}
	return (NULL);
}

t_pipeline	*build_pipeline(int n_cmds)
{
	t_pipeline	*pl;
	int			i;

	pl = malloc(sizeof(t_pipeline));
	if (!pl)
		return (NULL);
	pl->n_cmds = n_cmds;
	pl->pids = malloc(sizeof(pid_t) * n_cmds);
	pl->pipes = malloc(sizeof(int) * 2 * (n_cmds - 1));
	if (!pl->pids || (n_cmds > 1 && !pl->pipes))
		return (pipeline_fail(pl));
	i = 0;
	while (i < n_cmds - 1)
	{
		if (pipe(pl->pipes + i * 2) == -1)
			return (pipeline_fail(pl));
		i++;
	}
	return (pl);
}
```
Allocates both arrays and creates **every** `pipe()` up front, before any
`fork()` happens. `pl->pipes` is a flat array of `2*(n_cmds-1)` fds rather
than an array of `int[2]` pairs — simpler indexing (`pipes[i*2]` /
`pipes[i*2+1]` for pipe `i`'s read/write ends) without the slightly
awkward pointer-to-array-of-2 C syntax. The `(n_cmds > 1 && !pl->pipes)`
guard matters: for a single command, `malloc(sizeof(int) * 2 * 0)` is a
zero-byte allocation that may legitimately return `NULL` on some libc
implementations without that being a real failure — this only treats a
`NULL` `pipes` array as fatal when pipes are actually needed.
`pipeline_fail` centralizes the "free whatever was allocated so far,
return `NULL`" cleanup so both failure sites (the initial mallocs, and a
`pipe()` call failing partway) share one path instead of duplicating it —
a real simplification the refactor produced, not just a norm workaround.

```c
void	wire_pipes(t_pipeline *pl, int idx)
{
	if (idx > 0)
		dup2(pl->pipes[(idx - 1) * 2], STDIN_FILENO);
	if (idx < pl->n_cmds - 1)
		dup2(pl->pipes[idx * 2 + 1], STDOUT_FILENO);
}
```
For pipeline position `idx`: if it's not the first command, its stdin
comes from the *previous* pipe's read end; if it's not the last, its
stdout goes to *its own* pipe's write end. The first command's stdin and
the last command's stdout are left completely alone — still whatever they
were inherited from the shell (the real terminal, or in turn from a
redirection applied afterward, see `redirect.c` below — the ordering
`wire_pipes` then `apply_redirs` in `run_child` matters exactly here,
since an explicit `<`/`>` on a command must win over the pipe wiring).

```c
void	close_pipes(t_pipeline *pl)
{
	int	i;

	i = 0;
	while (i < (pl->n_cmds - 1) * 2)
	{
		close(pl->pipes[i]);
		i++;
	}
}
```
Closes every pipe fd — called by **each child** (after `wire_pipes` has
already `dup2`'d the one or two it needs, so the original numbered fds
are redundant copies by then) and by the **parent**, once, right after
forking every child. The parent call matters for a subtle but critical
reason: `fork()` duplicates the *entire* fd table, so every child
inherits every pipe fd regardless of whether it uses it. If the parent
kept its own copies open while waiting, the *last* command's stdin would
never see EOF from the second-to-last command's output — there'd always
be at least one lingering writable reference (the parent's) keeping the
pipe artificially "open." This is the classic pipeline-fd-leak deadlock,
avoided here just by closing everything, everywhere, the moment it's no
longer needed.

```c
void	free_pipeline(t_pipeline *pl)
{
	free(pl->pipes);
	free(pl->pids);
	free(pl);
}
```
Plain teardown, called once by `execute()` after the whole pipeline has
been waited on.

---

## 4. `src/execution/path.c` — finding the executable

```c
static char	*join_path(const char *dir, const char *cmd)
{
	char	*tmp;
	char	*full;

	tmp = ft_strjoin(dir, "/");
	if (!tmp)
		return (NULL);
	full = ft_strjoin(tmp, cmd);
	free(tmp);
	return (full);
}
```
`dir + "/" + cmd`, two joins since libft has no three-way join.

```c
static int	try_candidate(char *candidate, int *exit_code)
{
	if (!candidate)
		return (0);
	if (access(candidate, F_OK) != 0)
	{
		free(candidate);
		return (0);
	}
	if (access(candidate, X_OK) == 0)
		return (1);
	*exit_code = 126;
	free(candidate);
	return (0);
}
```
This is where the 126-vs-127 distinction (Decision #15) actually happens:
`access(F_OK)` (does anything exist at this path at all?) is checked
*before* `access(X_OK)` (can it be executed?). A candidate that doesn't
exist at all is simply not a match (the search continues to the next
`PATH` directory); a candidate that *exists* but isn't executable sets
`*exit_code = 126` — deliberately *not* returning immediately, since bash
itself keeps searching the rest of `PATH` after finding a non-executable
match, in case a *later* directory has a usable one. If the whole search
comes up empty, whatever `*exit_code` was left at (127 by default, from
`resolve_executable` below, or 126 if a non-executable match was seen
along the way) is what the caller reports.

```c
static char	*search_path(const char *cmd, t_env *env, int *exit_code)
{
	char	*path_val;
	char	**dirs;
	char	*candidate;
	int		i;

	path_val = env_get(env, "PATH");
	if (!path_val)
		return (NULL);
	dirs = ft_split(path_val, ':');
	if (!dirs)
		return (NULL);
	i = 0;
	while (dirs[i])
	{
		candidate = join_path(dirs[i], cmd);
		if (try_candidate(candidate, exit_code))
		{
			free_split(dirs);
			return (candidate);
		}
		i++;
	}
	free_split(dirs);
	return (NULL);
}
```
No `PATH` set at all (`env_get` returns `NULL`) means nothing to search —
a bare command name simply can't be found, matching real shell behavior.
Otherwise, split on `:` and try each directory in order, stopping at the
first real hit.

```c
char	*resolve_executable(const char *cmd, t_env *env, int *exit_code)
{
	*exit_code = 127;
	if (ft_strchr(cmd, '/'))
	{
		if (access(cmd, F_OK) != 0)
			return (NULL);
		if (access(cmd, X_OK) != 0)
		{
			*exit_code = 126;
			return (NULL);
		}
		return (ft_strdup(cmd));
	}
	return (search_path(cmd, env, exit_code));
}
```
The public entry point: default to 127 (matches bash's default when
nothing at all is found), then branch on whether `cmd` contains a `/` at
all — a relative or absolute path is checked directly (never searched in
`PATH`, exactly like real bash), otherwise delegate to the `PATH` search.

---

## 5. `src/execution/exec_arrays.c` — building `execve`'s arguments

```c
char	**build_argv(t_token *args)
{
	int		n;
	char	**argv;
	t_token	*cur;
	int		i;

	n = 0;
	cur = args;
	while (cur)
	{
		n++;
		cur = cur->next;
	}
	argv = malloc(sizeof(char *) * (n + 1));
	if (!argv)
		return (NULL);
	i = 0;
	while (args)
	{
		argv[i] = args->value;
		i++;
		args = args->next;
	}
	argv[i] = NULL;
	return (argv);
}
```
Count, allocate, fill, `NULL`-terminate — the standard linked-list-to-`
argv` conversion. Note `argv[i] = args->value` — **not** a copy. By the
time this runs (inside a forked child, right before `execve`), `cmd->args`
is the final, fully-expanded `t_token` chain from step 6; reusing those
`value` pointers directly is safe and free, because this array only ever
needs to survive until `execve` (which replaces the process image
entirely) or `exit` (which ends the process) — whichever happens, nothing
here is ever explicitly freed, and nothing needs to be: the OS reclaims
everything the moment the process is gone. This is standard, expected
practice for a forked child that's about to `exec` or die.

```c
static int	count_env(t_env *env)
{
	...
}

static char	*env_entry(t_env *env)
{
	char	*eq;
	char	*entry;
	char	*value;

	eq = ft_strjoin(env->key, "=");
	if (env->value)
		value = env->value;
	else
		value = "";
	entry = ft_strjoin(eq, value);
	free(eq);
	return (entry);
}

char	**build_envp(t_env *env)
{
	...
}
```
Same count/allocate/fill shape, but each entry is a freshly built
`"KEY=VALUE"` string (`env_entry`), since `execve`'s third argument needs
that exact format, not the linked list's separate `key`/`value` fields.
Built from scratch on **every** command — not cached anywhere on
`t_shell` — so that once `export`/`unset` exist (step 8) and can actually
change `shell->env` between one command and the next, there's no stale
cached array to accidentally hand to a later `execve`. `env->value ?
env->value : ""` was originally a ternary here; Norminette forbids
ternaries outright, so it's a plain `if`/`else` instead — a real rule,
not a stylistic quirk, and one worth remembering for future steps.

---

## 6. `src/execution/redirect.c` — applying `<` / `>` / `>>`

```c
static int	redir_flags(t_redir_type type)
{
	if (type == REDIR_IN)
		return (O_RDONLY);
	if (type == REDIR_APPEND)
		return (O_WRONLY | O_CREAT | O_APPEND);
	return (O_WRONLY | O_CREAT | O_TRUNC);
}
```
The three non-heredoc redirection types map directly to `open()` flags;
`REDIR_OUT` is the fallback (`O_TRUNC`), since it's the only remaining
possibility once `IN` and `APPEND` are ruled out.

```c
static int	apply_one_redir(t_redir *redir)
{
	int	fd;

	if (redir->type == REDIR_HEREDOC)
	{
		dup2(redir->heredoc_fd, STDIN_FILENO);
		close(redir->heredoc_fd);
		return (0);
	}
	fd = open(redir->target->value, redir_flags(redir->type), 0644);
	if (fd == -1)
	{
		perror(redir->target->value);
		return (-1);
	}
	if (redir->type == REDIR_IN)
		dup2(fd, STDIN_FILENO);
	else
		dup2(fd, STDOUT_FILENO);
	close(fd);
	return (0);
}
```
A heredoc doesn't call `open()` at all here — by the time a child reaches
this point, `redir->heredoc_fd` was already resolved (opened, read,
closed, reopened read-only, unlinked) by `resolve_heredocs` back in the
parent, *before* any forking — this function just wires that already-open
fd onto stdin. Every other type opens its target file fresh, checks for
failure (`perror` prints exactly the filename that failed, matching how
bash reports it), and `dup2`s onto the correct standard descriptor.

```c
int	apply_redirs(t_redir *redirs)
{
	while (redirs)
	{
		if (apply_one_redir(redirs) == -1)
			return (-1);
		redirs = redirs->next;
	}
	return (0);
}
```
Walks the whole list **in order**, applying each one. There's no special
handling anywhere for "only the last redirection of a given direction
actually matters" (e.g. `cmd > a > b` should only leave `b` attached) —
applying every one in sequence, each `dup2` simply overwriting whatever
the previous one attached, produces exactly that behavior automatically,
side effects included (an earlier `> a` still truncates `a` on disk even
though `b` ends up being the one actually used) — this matches real bash
without writing any code specifically for it.

---

## 7. `src/execution/heredoc.c` — `<<`

```c
#define HEREDOC_TMP "/tmp/.minishell_heredoc"

static int	is_delim(const char *line, const char *delim)
{
	return (ft_strlen(line) == ft_strlen(delim)
		&& ft_strncmp(line, delim, ft_strlen(delim) + 1) == 0);
}
```
Exact-match check (length first, then content) — a heredoc delimiter must
match a whole line exactly, not just as a prefix.

```c
static void	write_line(int fd, char *line, int want_expand, t_shell *shell)
{
	char	*out;

	if (want_expand)
		out = expand_fragment(line, shell);
	else
		out = ft_strdup(line);
	write(fd, out, ft_strlen(out));
	write(fd, "\n", 1);
	free(out);
}

static int	heredoc_body(const char *delim, int want_expand, t_shell *shell)
{
	int		fd;
	char	*line;

	fd = open(HEREDOC_TMP, O_CREAT | O_WRONLY | O_TRUNC, 0600);
	if (fd == -1)
		return (-1);
	line = readline("> ");
	while (line && !is_delim(line, delim))
	{
		write_line(fd, line, want_expand, shell);
		free(line);
		line = readline("> ");
	}
	free(line);
	close(fd);
	fd = open(HEREDOC_TMP, O_RDONLY);
	unlink(HEREDOC_TMP);
	return (fd);
}
```
The heart of Decision #13: rather than a `pipe()` (whose kernel buffer —
commonly 64KB — could deadlock the parent's `write()` if a heredoc body
were large enough, since nothing is reading the other end until a child
is actually forked and `execve`'d, which hasn't happened yet at this
point), the body is written into a **temp file**: opened fresh, every
(optionally expanded) line appended, closed, **reopened read-only**, and
**unlinked** immediately. That last step matters and is a real Unix
guarantee, not a hack: removing a file's name doesn't invalidate an
already-open file descriptor referencing it — the underlying inode stays
alive exactly as long as something still has it open. So the returned fd
remains perfectly valid to read from later, and nothing is ever left
behind on disk, even if the shell were killed between here and using it.
Reusing one single fixed path (rather than a per-heredoc-unique one) is
safe specifically *because* heredocs are resolved one at a time,
sequentially, entirely within one process, before any forking — by the
time a second heredoc's `open(... O_TRUNC)` reuses the same name, the
first one's read fd is already fully detached from that name (unlinked)
and completely unaffected by the name being reused for something new.
`ft_strlen(line) == ft_strlen(delim) &&` guards a subtlety worth codifying
here: without the length check first, `ft_strncmp` alone could accept a
`line` that's merely a *prefix* of a longer `delim`, since `ft_strncmp` (no
`ft_strcmp` exists in this libft) only ever compares a bounded number of
bytes.

```c
static void	resolve_cmd_heredocs(t_cmd *cmd, t_shell *shell)
{
	...
}

void	resolve_heredocs(t_shell *shell)
{
	t_cmd	*cmd;

	cmd = shell->pipeline;
	while (cmd)
	{
		resolve_cmd_heredocs(cmd, shell);
		cmd = cmd->next;
	}
}
```
Walks **every** command in the pipeline, resolving every heredoc on every
one of them, all before any `fork()` — matching bash's real behavior:
heredocs are collected once, up front, for the entire line, regardless of
how many pipe stages follow. (An earlier version of this function
returned whether a Ctrl-C had aborted the whole thing, wired into a
heredoc-specific signal handler — removed after testing showed it
unreliable; see section 8 and Decision #16 for the full story.)

---

## 8. `src/shell/signals_exec.c` — Ctrl-C/Ctrl-\ while a command runs

```c
void	signals_ignore_during_exec(void)
{
	signal(SIGINT, SIG_IGN);
	signal(SIGQUIT, SIG_IGN);
}

void	signals_child_default(void)
{
	signal(SIGINT, SIG_DFL);
	signal(SIGQUIT, SIG_DFL);
}
```
The whole mechanism, and it's simpler than it might look: no process
groups, no `tcsetpgrp`, nothing job-control-related is needed at all,
because every child inherits the shell's *own* process group via `fork()`
by default — a terminal-generated Ctrl-C/Ctrl-\ is delivered to the
*entire* foreground group, parent and children alike, automatically. So
the only thing that needs arranging is: right before forking anything,
the **parent** sets both signals to `SIG_IGN` (so the delivery still
happens, but the shell process itself simply discards it — no action,
survives untouched); right after `fork()`, **before doing anything
else** (wiring pipes, applying redirects, resolving the executable), each
**child** resets both back to `SIG_DFL` — plain default disposition,
meaning the child terminates on `SIGINT` / dumps core on `SIGQUIT` exactly
like any ordinary foreground program run from a real bash would. Once
every child has been waited on, `execute()` calls `init_signals()` again
(unchanged from step 2) to restore the normal interactive prompt
handlers.

**What was tried and rolled back**: a heredoc-specific `SIGINT` handler
originally existed here too (`handle_sigint_heredoc` / `init_signals_
heredoc`), installed only while `resolve_heredocs` was running, meant to
force the current `readline("> ")` call to return early via readline's
public `rl_done` flag — the standard documented technique for aborting a
blocking `readline()` call from within a signal handler — so that Ctrl-C
during heredoc entry could abort the *entire* command the way real bash
does, setting `$?` to 130. Tested under a real pty (not just assumed to
work because the code looked reasonable), it turned out **unreliable**:
depending on exact byte-level timing between the signal arriving and the
next input being sent, `rl_done` sometimes forced readline to return
immediately and sometimes didn't (the same `readline("> ")` call would
just keep waiting for more heredoc input despite the flag being set) —
this held even after adding every readline signal-cleanup function
documented for exactly this situation (`rl_free_line_state`,
`rl_cleanup_after_signal`, `rl_clear_pending_input`). Since shipping a
feature that behaves inconsistently depending on timing nobody can fully
control is worse than not having it, this was removed — Ctrl-C during
heredoc entry now behaves exactly like Ctrl-C at the main prompt (the
same, already-proven-solid handler from step 2 stays installed the whole
time: fresh prompt, keep waiting for more heredoc lines). Full account in
Decision #16. Ctrl-C killing an actual **running foreground command**
(the mechanism described just above, not readline-related at all) was
verified solid across many repeated pty runs and is not affected by this.

---

## 9. `src/execution/child.c` — what one forked child does

```c
static void	child_fail(const char *name, int code)
{
	if (code == 127)
	{
		ft_putstr_fd("minishell: ", STDERR_FILENO);
		ft_putstr_fd((char *)name, STDERR_FILENO);
		ft_putstr_fd(": command not found\n", STDERR_FILENO);
	}
	else
		perror(name);
	exit(code);
}

void	run_child(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx)
{
	char	*path;
	char	**argv;
	char	**envp;
	int		code;

	signals_child_default();
	wire_pipes(pl, idx);
	close_pipes(pl);
	if (apply_redirs(cmd->redirs) == -1)
		exit(1);
	if (!cmd->args)
		exit(0);
	path = resolve_executable(cmd->args->value, shell->env, &code);
	if (!path)
		child_fail(cmd->args->value, code);
	argv = build_argv(cmd->args);
	envp = build_envp(shell->env);
	execve(path, argv, envp);
	perror(path);
	exit(126);
}
```
The exact order matters and mirrors the reasoning built up across the
sections above: reset signals first (section 8), then wire this
command's pipe connections (section 3) *before* applying its own
redirections (section 6) — so an explicit `<`/`>` correctly overrides the
pipe wiring rather than the other way around — then close every leftover
pipe fd. A redirection failure exits with status `1` (Decision #15); a
command consisting of *only* redirections and no actual name (e.g. one
stage of `< in | > out`, a valid pipeline stage per step 4's own
validation rules) simply `exit(0)`s once its redirections are applied —
there's genuinely nothing else for it to do, matching real bash's
observable behavior for the same case even though bash technically
avoids forking for it in the single-command case (Decision #12). If
`resolve_executable` fails, `child_fail` picks the right message and exit
code (127 vs. 126, section 4); if `execve` itself somehow fails despite a
resolved path existing (a directory given where an executable was
expected, a corrupt binary, etc.), `perror` reports it and the child
exits 126 — `execve` only ever returns on failure, so reaching the line
after it always means something went wrong.

---

## 10. `src/execution/wait_status.c` — turning a wait status into `$?`

```c
static int	last_status(int status)
{
	if (WIFSIGNALED(status))
	{
		if (WTERMSIG(status) == SIGINT)
			write(STDOUT_FILENO, "\n", 1);
		else if (WTERMSIG(status) == SIGQUIT)
			ft_putstr_fd("Quit (core dumped)\n", STDERR_FILENO);
		return (128 + WTERMSIG(status));
	}
	return (WEXITSTATUS(status));
}

int	wait_all(t_pipeline *pl)
{
	int	i;
	int	status;
	int	result;

	i = 0;
	result = 0;
	while (i < pl->n_cmds)
	{
		waitpid(pl->pids[i], &status, 0);
		if (i == pl->n_cmds - 1)
			result = last_status(status);
		i++;
	}
	return (result);
}
```
Every child is waited on (reaping every one is necessary regardless of
which one's status matters, to avoid leaving zombie processes behind),
but only the **last** command's status becomes `shell->exit_status` —
matching the subject's own wording, "the exit status of the most recently
executed foreground pipeline," and matching bash's default behavior
(without an explicit `PIPESTATUS`-style feature, which isn't asked for).
`last_status` converts a raw `wait()` status into bash's own convention:
a normally-exited process contributes its real exit code; a
signal-killed one contributes `128 + signal number` (130 for `SIGINT`,
131 for `SIGQUIT`) — and, matching bash exactly, prints a bare newline in
the `SIGINT` case (so the next prompt starts on a clean line) or `Quit
(core dumped)` in the `SIGQUIT` case, printed unconditionally the moment
that termination is detected, regardless of whether an actual core file
was written (that depends on `ulimit`, which is a separate concern bash
itself doesn't check before printing this message either).

---

## 11. `src/execution/execute.c` — the driver

```c
static int	count_cmds(t_cmd *pipeline)
{
	...
}

static int	fork_cmd(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx)
{
	pid_t	pid;

	pid = fork();
	if (pid == -1)
	{
		perror("minishell: fork");
		return (-1);
	}
	if (pid == 0)
		run_child(cmd, shell, pl, idx);
	pl->pids[idx] = pid;
	return (0);
}

static void	fork_all(t_cmd *pipeline, t_shell *shell, t_pipeline *pl)
{
	...
}

void	close_heredoc_fds(t_cmd *pipeline)
{
	...
}

void	execute(t_shell *shell)
{
	t_pipeline	*pl;

	resolve_heredocs(shell);
	pl = build_pipeline(count_cmds(shell->pipeline));
	if (!pl)
		return ;
	signals_ignore_during_exec();
	fork_all(shell->pipeline, shell, pl);
	close_pipes(pl);
	close_heredoc_fds(shell->pipeline);
	shell->exit_status = wait_all(pl);
	init_signals();
	free_pipeline(pl);
}
```
The whole shape of this step, laid out in nine lines: resolve every
heredoc for the whole pipeline first (section 7); build the pipe/pid
bookkeeping (section 3); ignore signals in the parent (section 8); fork
every command (`fork_cmd` runs `run_child` in the child branch — which
never returns — and records the pid in the parent branch); once every
child exists, the parent closes every pipe fd it's still holding *and*
every heredoc fd it resolved earlier (children already closed their own
copies inside `apply_one_redir`, but the parent's original copies from
`resolve_heredocs` are still open and would otherwise leak slowly across
however many command lines a long interactive session runs); wait for
everyone and record the last command's status (section 10); restore the
interactive signal handlers; free the pipeline bookkeeping. `if (!pl)
return ;` is the one place a `build_pipeline` allocation failure is
handled — nothing was forked yet at that point, so there's nothing to
clean up beyond just not proceeding.

---

## 12. `src/shell/shell.c` — wiring it in, and deleting the scaffolding

```c
else if (shell->tokens)
{
	shell->pipeline = parse(&shell->tokens);
	if (shell->pipeline)
	{
		expand(shell);
		execute(shell);
	}
	free_cmd(shell->pipeline);
	shell->pipeline = NULL;
}
```
The one-line change from step 6: `execute(shell)` replaces
`debug_print_pipeline(shell->pipeline)`. `src/shell/debug_pipeline.c` — the temporary
visualization every step from 3 through 6 explicitly flagged as
scaffolding-not-a-feature — is deleted entirely this step, along with its
declaration in `inc/minishell.h` and its entry in the `Makefile`. This is
the payoff of that running promise: the AST is finally consumed for real.

---

## Full call chain for one input line, end to end (current state)

`shell_loop` -> `readline` -> (if non-empty) `add_history` -> `process_line`
-> `tokenize` (step 3) -> `validate_tokens` (step 4) -> `parse` (step 5)
-> `expand` (step 6) -> `execute`
(-> `resolve_heredocs` -> `resolve_cmd_heredocs` -> `heredoc_body` ->
`write_line` -> `expand_fragment`, per line;
-> `build_pipeline`;
-> `signals_ignore_during_exec`;
-> `fork_all` -> `fork_cmd` -> (child:) `run_child` -> `signals_child_
default` / `wire_pipes` / `close_pipes` / `apply_redirs` -> `apply_one_
redir` / `resolve_executable` -> `search_path` -> `try_candidate` /
`build_argv` / `build_envp` -> `execve` or `child_fail`;
-> `close_pipes` / `close_heredoc_fds` / `wait_all` -> `last_status`;
-> `init_signals`; -> `free_pipeline`)
-> `free_cmd` -> loop back to `readline`.

Verified with piped smoke tests (pipes, all three non-heredoc
redirections including reading files back to confirm truncate-vs-append,
a nonexistent command's exit code, both quoted and unquoted heredoc
delimiters, a 3-stage pipeline) and real pty tests (Ctrl-C killing a
running foreground command, confirmed solid across repeated runs, `$?`
correctly reading back `130` afterward). `valgrind --leak-check=full`
over the parent process: 0 definitely/indirectly/possibly lost bytes.

Every command name is still `PATH`-searched and `execve`'d, even
`cd`/`export`/`unset`/`exit` — that's **Step 8 (builtins)**, per
`PROGRESS.md`, which is also where a single builtin with no pipe finally
gets to run without forking, so it can actually mutate the shell's own
state.

# Step 1–2 — Line-by-line explanation

Covers: **Step 1 — Project skeleton** (Makefile, headers, REPL loop) and
**Step 2 — Signal handling baseline**, per `PROGRESS.md`.

Files walked, in the order the program actually executes:
`inc/structs.h` -> `inc/minishell.h` -> `src/main/main.c` -> `src/env/env.c`
-> `src/shell/signals.c` -> `src/shell/shell.c`.

---

## 1. `inc/structs.h` — the data model everything else depends on

```c
#ifndef STRUCTS_H
# define STRUCTS_H
```
Standard include guard. Without it, if two `.c` files both `#include "minishell.h"` and that pulls in `structs.h` twice in one translation unit (e.g. through two different header chains), the compiler would see `typedef struct s_env {...} t_env;` twice and error out with a redefinition. The guard makes the second `#include` a no-op.

```c
typedef struct s_env
{
	char			*key;
	char			*value;
	struct s_env	*next;
}	t_env;
```
A singly linked list node representing one environment variable.
- `key` — the variable name (`"PATH"`), heap-allocated, owned by this node.
- `value` — the variable's value (`"/usr/bin:..."`), heap-allocated, owned by this node. Can be `NULL` — see `env_init` below for why that's a real case, not a bug guard.
- `next` — pointer to the next node; `struct s_env *` (not `t_env *`) is required here because at the point this line is parsed, the `typedef` name `t_env` doesn't exist yet — only the tag `struct s_env` is in scope inside its own definition.

```c
typedef struct s_shell
{
	t_env	*env;
	int		exit_status;
	int		interactive;
}	t_shell;
```
The top-level shell state, one instance of which lives on `main`'s stack for the whole program lifetime.
- `env` — head of the linked list above.
- `exit_status` — becomes the process's real exit code (`main` returns this at the end); also what `$?` will report once expansion is implemented.
- `interactive` — whether stdin is a terminal (set via `isatty`), which shells use to decide things like whether to ignore `SIGQUIT` and print a prompt.

```c
#endif
```
Closes the include guard.

---

## 2. `inc/minishell.h` — the shared contract

```c
#ifndef MINISHELL_H
# define MINISHELL_H

# include <stdio.h>
# include <stdlib.h>
# include <unistd.h>
# include <string.h>
# include <errno.h>
# include <signal.h>
# include <fcntl.h>
# include <sys/types.h>
# include <sys/wait.h>
# include <sys/stat.h>
# include <dirent.h>
# include <readline/readline.h>
# include <readline/history.h>
# include "libft.h"
# include "structs.h"
```
Same include-guard pattern as above. The system headers are a superset of what steps 1–2 currently need (`stdio`/`stdlib`/`unistd` for I/O and process basics, `signal.h` for `sigaction`, `readline/*` for the prompt/history) — the rest (`fcntl.h`, `sys/wait.h`, `sys/stat.h`, `dirent.h`) are pre-declared now because they'll be needed for redirections, `wait()`/forking, and later builtins (`cd`, wildcard globbing), so they don't have to be added file-by-file later. `libft.h` pulls in the custom string/list helper library; `structs.h` pulls in the two typedefs above.

```c
extern int	g_signal;
```
Declares (doesn't define) the one global the subject explicitly permits. `extern` means "this variable exists somewhere else (in `signals.c`), just let every `.c` file that includes this header link against it."

This was originally typed `volatile sig_atomic_t` — the C-standard type guaranteed to be read/written as a single atomic operation inside a signal handler, with `volatile` forcing the compiler to re-read it from memory instead of caching a stale value in a register across `handle_sigint`'s asynchronous writes. It was later changed to plain `int`, a deliberate deviation from that signal-safety guarantee (see PROGRESS.md Decision #3) — reads/writes to `g_signal` are no longer guaranteed atomic or free of compiler caching, so the handler racing with the main program is a real (if narrow) possibility now.

```c
// shell
void	shell_loop(t_shell *shell);
void	free_shell(t_shell *shell);

// signals
void	init_signals(void);

// env
t_env	*env_init(char **envp);
void	free_env(t_env *env);

#endif
```
Forward declarations grouped by source file, so `main.c` can call functions defined in `shell.c`, `signals.c`, and `env.c` without needing their bodies visible at compile time — the linker resolves the actual addresses later. The `// shell` / `// signals` / `// env` comments are just navigation aids matching the file layout.

---

## 3. `src/main/main.c` — the entry point

```c
#include "minishell.h"

static void	init_shell(t_shell *shell, char **envp)
{
	shell->env = env_init(envp);
	shell->exit_status = 0;
	shell->interactive = isatty(STDIN_FILENO);
}
```
`static` restricts this function's linkage to this translation unit only — it's an internal helper, not part of the header's public API, so it can't accidentally be called from another `.c` file and won't collide if another file defines its own `init_shell`.
- `shell->env = env_init(envp)` — builds the linked list of environment variables from the array the OS handed the process (see env.c below), and stores the list's head pointer in the struct.
- `shell->exit_status = 0` — a shell that hasn't run anything yet reports success (POSIX convention: 0 = success) if it exits immediately.
- `shell->interactive = isatty(STDIN_FILENO)` — `isatty` returns 1 if file descriptor 0 (stdin) is connected to a terminal device, 0 if it's a pipe/file/redirected input. This distinguishes `./minishell` typed at a terminal from `echo hi | ./minishell` or `./minishell < script`.

```c
int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	(void)argv;
```
`t_shell shell;` allocates the struct on `main`'s stack frame — no heap allocation for the top-level state, it just lives as long as the program runs. `argc`/`argv` are declared per the standard three-argument `main` signature but unused right now (minishell doesn't take command-line arguments in the subject); casting them to `(void)` is the idiomatic way to tell the compiler "yes, I know these are unused, don't warn me" without disabling the warning globally.

```c
	init_shell(&shell, envp);
	init_signals();
	shell_loop(&shell);
	free_shell(&shell);
	return (shell.exit_status);
}
```
Four-step lifecycle, each passing `&shell` by pointer (never by value, since it must be mutated by callees):
1. `init_shell` — populate the struct from `envp` as shown above.
2. `init_signals()` — install the `SIGINT`/`SIGQUIT` handling described below, *after* the struct exists but *before* the REPL starts reading input, so the very first `readline()` call is already protected.
3. `shell_loop(&shell)` — runs until EOF (Ctrl-D); currently just reads lines and echoes them into history (no execution wired up yet — that's steps 3–7).
4. `free_shell(&shell)` — releases the env list; returns to `main`.

`return (shell.exit_status)` — the process's real exit code becomes whatever the last command inside the shell set it to (currently always 0, since nothing sets it yet beyond the initial value).

---

## 4. `src/env/env.c` — turning `envp` into a linked list

```c
#include "minishell.h"

static t_env	*new_env_node(char *key, char *value)
{
	t_env	*node;

	node = malloc(sizeof(t_env));
	if (!node)
		return (NULL);
	node->key = key;
	node->value = value;
	node->next = NULL;
	return (node);
}
```
A small factory function. Note it takes ownership of `key`/`value` — it does *not* `strdup` them itself, it just stores whatever pointers the caller already allocated. `malloc` failure is checked and propagated as `NULL` rather than crashing (though note: nothing upstream currently checks this `NULL` before dereferencing in `env_add_back` — that's a latent gap worth flagging for later, not something to silently work around).

```c
static void	env_add_back(t_env **head, t_env *new)
{
	t_env	*last;

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
Classic append-to-tail on a singly linked list. Takes `t_env **head` (pointer to the caller's head pointer) because the very first insertion needs to *modify* the caller's `head` variable itself (turn it from `NULL` into the new node), which is impossible through a plain `t_env *` parameter — C passes by value, so a `t_env *head` parameter would just be a local copy. For every insertion after the first, it walks to the last node (`while (last->next)`) and links the new node after it — O(n) per insert, O(n²) total for n variables, which is fine given `envp` is typically a few dozen entries.

```c
t_env	*env_init(char **envp)
{
	t_env	*head;
	t_env	*node;
	char	*eq;
	int		i;

	head = NULL;
	i = 0;
	while (envp[i])
	{
		eq = ft_strchr(envp[i], '=');
		if (eq)
			node = new_env_node(ft_substr(envp[i], 0, eq - envp[i]),
					ft_strdup(eq + 1));
		else
			node = new_env_node(ft_strdup(envp[i]), NULL);
		env_add_back(&head, node);
		i++;
	}
	return (head);
}
```
`envp` is the NULL-terminated array of `"KEY=VALUE"` C-strings the OS/shell that launched this process handed it. The loop walks it until the sentinel `NULL` entry.
- `ft_strchr(envp[i], '=')` — finds the *first* `=` in the string (custom libft version of the standard `strchr`), returning a pointer into `envp[i]` at that character, or `NULL` if there's no `=` at all.
- If found: `ft_substr(envp[i], 0, eq - envp[i])` copies out everything *before* the `=` as the key — `eq - envp[i]` is pointer arithmetic giving the number of bytes from the start of the string to the `=`, i.e. the key's length. `ft_strdup(eq + 1)` duplicates everything *after* the `=` as the value (`eq + 1` skips past the `=` itself).
- If not found (malformed entry with no `=` at all — rare but technically possible in a crafted environment): the whole string becomes the key, and `value` is explicitly `NULL`. This is exactly why `t_env.value` is documented as nullable rather than always-a-string — this is a deliberate real code path, not defensive dead code.
- `env_add_back(&head, node)` — append, as above.
- Returns the built list's head.

```c
void	free_env(t_env *env)
{
	t_env	*next;

	while (env)
	{
		next = env->next;
		free(env->key);
		free(env->value);
		free(env);
		env = next;
	}
}
```
Standard linked-list teardown. `next` is saved *before* `free(env)` because reading `env->next` after `env` has been freed would be a use-after-free. `free(NULL)` is well-defined as a no-op in C, so `free(env->value)` is safe even for the malformed-entry case where `value` is `NULL`.

---

## 5. `src/shell/signals.c` — Ctrl-C without killing the shell

```c
#include "minishell.h"

int	g_signal = 0;
```
The actual definition (allocates storage) matching the `extern` declaration in the header. Initialized to 0, meaning "no signal pending."

```c
static void	handle_sigint(int sig)
{
	g_signal = sig;
	write(STDOUT_FILENO, "\n", 1);
	rl_on_new_line();
	rl_replace_line("", 0);
	rl_redisplay();
}
```
This is a signal handler — it runs asynchronously, interrupting whatever the main program was doing (almost always, here, blocked inside `readline()`'s own internal `read()`). That imposes a hard constraint: only async-signal-safe functions may be called inside it.
- `g_signal = sig` — records which signal fired (`SIGINT`'s numeric value) into the global, for the parser/executor to inspect later once heredocs and exit-status reporting need to know "was the last thing interrupted by Ctrl-C".
- `write(STDOUT_FILENO, "\n", 1)` — the raw `write(2)` syscall is on the POSIX async-signal-safe list; `printf`/`ft_putstr_fd`-if-it-buffers would not be safe to call from a handler, since stdio buffering isn't reentrant.
- `rl_on_new_line()` — tells readline's internal cursor-tracking state that the terminal cursor is now on a fresh line (because the `\n` above just moved it), so readline's next redraw computes cursor position correctly instead of assuming it's still mid-line.
- `rl_replace_line("", 0)` — clears whatever partial input the user had typed on the interrupted line, so Ctrl-C behaves like real bash: it abandons the current input rather than keeping it around.
- `rl_redisplay()` — forces readline to redraw the prompt immediately, so the user sees a fresh `minishell$ ` right after their `^C` instead of a blank terminal until the next keystroke.

These `rl_*` functions are technically not on the strict POSIX async-signal-safe list (they're readline internals, not syscalls), but this is the standard, widely-used approach in minishell projects for this exact reason — it's called out in the project's own `PROGRESS.md` as a "signal-safety nuance" that was already discussed and accepted knowingly, not an oversight.

```c
void	init_signals(void)
{
	struct sigaction	sa_int;

	sa_int.sa_handler = handle_sigint;
	sigemptyset(&sa_int.sa_mask);
	sa_int.sa_flags = 0;
	sigaction(SIGINT, &sa_int, NULL);
	signal(SIGQUIT, SIG_IGN);
}
```
- `struct sigaction sa_int` declared on the stack, then filled in field by field (not zero-initialized first — every field actually used here *is* explicitly set, so this is safe; if the struct had more fields needing a defined value, that would need review, but it doesn't in this case).
- `sa_int.sa_handler = handle_sigint` — install the function above as the handler.
- `sigemptyset(&sa_int.sa_mask)` — the `sa_mask` field lists which *other* signals should be blocked while this handler is running; empty means "block nothing extra," i.e. don't add any masking beyond the default (the signal that triggered the handler is auto-blocked by the kernel for its own duration anyway).
- `sa_int.sa_flags = 0` — no special behavior flags (e.g. no `SA_RESTART`, which would auto-restart certain interrupted syscalls — deliberately left off here so that `readline()`'s internal read *does* get interrupted and return, letting the REPL redraw the prompt rather than silently resuming the old read).
- `sigaction(SIGINT, &sa_int, NULL)` — installs the config for `SIGINT` (Ctrl-C); `sigaction` is used instead of the simpler `signal()` specifically so `sa_flags`/`sa_mask` can be controlled explicitly rather than relying on unspecified/legacy semantics that vary by platform.
- `signal(SIGQUIT, SIG_IGN)` — Ctrl-`\` (`SIGQUIT`) is set to be ignored entirely, matching real interactive shell behavior (bash also ignores `SIGQUIT` at its own prompt; it only lets a *child* process see it, which will matter once execution/forking exists).

---

## 6. `src/shell/shell.c` — the REPL and cleanup

```c
#include "minishell.h"

void	shell_loop(t_shell *shell)
{
	char	*line;

	(void)shell;
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
		free(line);
	}
}
```
- `(void)shell` — the parameter is accepted now (so the function signature won't need to change later) but not yet used, since there's no tokenizing/executing yet to feed it into; this is intentional per `PROGRESS.md`, not dead code left by mistake.
- `while (1)` — infinite loop, exited only via `break` below.
- `line = readline("minishell$ ")` — GNU readline prints the prompt, handles line editing (arrow keys, history recall) interactively, and returns a heap-allocated string with the typed line (no trailing `\n`), or `NULL` specifically on EOF (Ctrl-D on an empty line, or stdin closed/redirected from an exhausted file).
- `if (!line)` — EOF case: print `"exit\n"` (mimicking bash's behavior of announcing `exit` when you Ctrl-D out of an interactive shell) and `break` out of the loop, ending the program.
- `if (*line) add_history(line)` — `*line` dereferences the first character; this is `true` unless the line is empty (`""`, i.e. the user just hit Enter). Real shells don't clutter history with blank lines, so this guards `add_history` (a readline function that appends to the in-memory/`.` history list) to skip them.
- `free(line)` — `readline()` allocates the returned string with `malloc`; the caller owns it and must free it every iteration, or every Enter-press leaks memory. Note history has its own internal copy (`add_history` duplicates the string), so freeing here doesn't invalidate what's in history.
- Nothing is tokenized, parsed, or executed yet — this loop currently only proves the read/prompt/history/EOF/signal machinery works, which is exactly what `PROGRESS.md` step 1–2 scope says it should do.

```c
void	free_shell(t_shell *shell)
{
	free_env(shell->env);
}
```
Called once from `main` right before returning. Currently only tears down the env list; will grow to free tokens/AST/etc. once those exist.

---

## Full call chain, end to end

`main` -> `init_shell` -> `env_init` -> `init_signals` -> `shell_loop`
(read -> optional `add_history` -> `free`, forever, until EOF) -> `free_shell`
-> `free_env` -> `return (shell.exit_status)`.

Nothing tokenizes or executes commands yet — that starts at **Step 3
(tokenizer)** per `PROGRESS.md`.

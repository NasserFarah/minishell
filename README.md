# Minishell

This project has been created as part of the 42 curriculum by fnasser
 && abdunass.

## Description
Minishell is a simplified implementation of a Unix shell written in C.
The objective of this project is to understand how shells work by recreating 
many of the core features of bash, including command parsing, process creation, 
pipes, redirections, environment variable expansion, and signal handling.
The shell reads user input, parses it into commands, executes built-in or external
programs, and manages processes while respecting the project's specifications.

## Features

- **Parsing & tokenizing**: quoting (`'single'` / `"double"`), operators
  (`|`, `<`, `>`, `>>`, `<<`), and syntax-error detection.
- **Expansion**: `$VAR` and `$?` expansion, tilde (`~`) expansion, and
  word-splitting, all quote-aware.
- **Redirections**: input (`<`), output (`>`), append (`>>`), and
  heredocs (`<<`) with optional expansion inside the heredoc body.
- **Pipelines**: arbitrary-length command chains connected with `|`.
- **Builtins**: `echo` (`-n`), `cd`, `pwd`, `export`, `unset`, `env`,
  `exit`.
- **External commands**: resolved against `PATH` (or run directly when
  given a relative/absolute path) and executed via `fork`/`execve`.
- **Environment management**: a linked-list env store backing `export`,
  `unset`, and `$VAR` expansion, exported to `envp` for child processes.
- **Signal handling**: `Ctrl-C` interrupts the prompt/heredoc without
  killing the shell, `Ctrl-\` is ignored at the prompt (as in bash), and
  signals are restored to default behavior in child processes.
- **Exit status**: `$?` tracks the exit code of the last foreground
  command/pipeline, including signal-based exits.

## Project layout

```
minishell/
├── inc/                    # minishell.h (prototypes), structs.h (data types)
├── libft/                  # custom libc replacement (used project-wide)
├── src/
│   ├── main/                main() entry point
│   ├── shell/                shell loop, line reading, signal handlers
│   ├── env/                   environment list (get/set/unset)
│   ├── tokenizer/               lexes the raw input line into tokens
│   ├── parser/                    turns tokens into a command/pipeline tree
│   ├── expansion/                   $VAR, $?, tilde, and word-split expansion
│   ├── execution/                     pipes, redirections, heredocs, fork/exec
│   └── builtin_functions/               echo, cd, pwd, export, unset, env, exit
└── Makefile
```
## Instructions
## Build

```sh
make        # builds libft, then the minishell binary
make clean  # removes object files
make fclean # removes object files and the minishell binary
make re     # fclean + make
```

Requires `cc` and the `readline` development headers/library
(`libreadline-dev` on Debian/Ubuntu).

## Usage

```sh
$ ./minishell
minishell$ ls -la
minishell$ echo "Hello, World!"
minishell$ cat file.txt | grep minishell > output.txt
minishell$ export FOO=bar
minishell$ echo $FOO
minishell$ cat << EOF
heredoc line
EOF
minishell$ exit
```

## Resources

- 42 Minishell subject
- Bash manual (`man bash`)
- POSIX Shell & Utilities specification
- GNU Readline documentation
- AI was used in this project for the following tasks:
- Making a plan and a roadmap
- Norminette and structure of the code files
- Explanation of concepts
- Debugging
- Making a tester

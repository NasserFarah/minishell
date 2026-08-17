This project has been created as part of the 42 curriculum by fnasser && abdunass.

Minishell

1) Description:

Minishell is a simplified implementation of a Unix shell written in C.
The objective of this project is to understand how shells work by recreating 
many of the core features of bash, including command parsing, process creation, 
pipes, redirections, environment variable expansion, and signal handling.
The shell reads user input, parses it into commands, executes built-in or external
programs, and manages processes while respecting the project's specifications.

2) Instructions:

Compile the project using:

$> make

This generates the executable:

minishell

Clean object files:

$> make clean

Remove all generated files:

$> make fclean

Recompile everything:

$> make re

run the program:
$> ./minishell

Example:

$> minishell$ ls -la
$> minishell$ echo "Hello, World!"
$> minishell$ cat file.txt | grep minishell > output.txt

3) Resources:
42 Minishell Subject
Bash Manual
POSIX Shell Specification
Linux Manual Pages
GNU Readline Documentation

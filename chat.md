me and my partner are splitting tasks in minishell project  and i took the execution and builtins part. where should i start and how help me

Absolutely — for a minishell, taking execution + builtins is a big but very manageable part. The best approach is to define a clean boundary between what parsing produces and what execution consumes.

1. First understand the expected pipeline

Your shell will roughly do:

Readline
   ↓
Lexer / Tokenizer
   ↓
Parser
   ↓
Command structure
   ↓
Expander (variables, quotes, etc.)
   ↓
Executor   ← YOUR MAIN AREA
   ↓
fork / pipe / redirect / execve

Before coding, talk with your partner and agree on the exact command structure the parser will give you.

For example, you ideally want something like:

typedef struct s_cmd
{
    char            **argv;
    char            *infile;
    char            *outfile;
    int             append;
    struct s_cmd    *next;
}   t_cmd;

Or a more generic redirection list:

typedef struct s_redir
{
    int             type;
    char            *filename;
    struct s_redir  *next;
}   t_redir;


typedef struct s_cmd
{
    char            **argv;
    t_redir         *redirs;
    struct s_cmd    *next;
}   t_cmd;

This interface is the first thing you should settle with your partner. Don't start building the executor until you know what data it receives.

2. Start with the easiest executor: one external command

Get this working first:

ls -la

The logic is basically:

fork()
├── Child
│   ├── prepare redirections
│   ├── find command path
│   └── execve()
│
└── Parent
    └── waitpid()

Conceptually:

pid = fork();
if (pid == 0)
{
    execve(path, cmd->argv, envp);
}
waitpid(pid, &status, 0);

Your first milestone should be:

ls
pwd
echo hello
/bin/ls
./some_program
command_that_doesnt_exist

Once this works, you have the foundation.

3. Then implement command path resolution

For a command like:

ls

you need to search through $PATH.

Example:

PATH=/usr/local/bin:/usr/bin:/bin

Your code should effectively try:

/usr/local/bin/ls
/usr/bin/ls
/bin/ls

But for:

/bin/ls
./program

you generally don't search PATH because the command already contains /.

Make a separate function for this:

char    *find_command_path(char *cmd, char **envp);

This keeps your executor much cleaner.

4. Builtins: separate them early

The required builtins are usually:

echo
cd
pwd
export
unset
env
exit

Make a function like:

int is_builtin(char *cmd);
int execute_builtin(t_shell *shell, t_cmd *cmd);

Something like:

if (is_builtin(cmd->argv[0]))
    execute_builtin(shell, cmd);
else
    execute_external(shell, cmd);
Important: some builtins must run in the parent

This is one of the most important concepts in minishell.

For example:

cd ..

If you do this:

fork()
   ↓
child changes directory
child exits

the parent shell stays in the old directory.

So this doesn't work:

cd ..
pwd

unless cd modifies the parent process.

Same idea for:

cd
export
unset
exit

because they modify shell state.

Good rule:

For a single builtin without a pipeline:

Builtin?
   ↓
Execute in PARENT

For:

echo hello | wc -c

echo needs to run in a child because it is part of a pipeline.

So:

Single builtin        → parent
Builtin in pipeline   → child
External command      → child
5. Implement builtins one by one

I would do them in this order:

pwd

Easy:

pwd

Use getcwd().

echo

Support:

echo hello
echo -n hello
echo -nnnn hello

Be careful with -n handling.

env

Print your environment.

cd

This is where shell state starts becoming important:

cd folder
cd ..
cd
cd -

You'll need to update PWD and probably OLDPWD.

export

You need to:

add variables
update existing variables
print exported variables when called without arguments

Examples:

export HELLO=world
export HELLO
export
unset

Remove variables:

unset HELLO
exit

Handle:

exit
exit 42
exit abc

This requires careful exit-status handling.

6. Then add redirections

After simple commands work:

echo hello > file
cat < file
echo hello >> file

You'll use:

open()
dup2()
close()

The concept:

echo hello > file

means:

open file
   ↓
dup2(file_fd, STDOUT_FILENO)
   ↓
execute echo

For input:

cat < file
open file
   ↓
dup2(file_fd, STDIN_FILENO)
   ↓
execute cat

Make this a separate function:

int apply_redirections(t_cmd *cmd);

Do not mix all the open/dup2 logic directly into your executor.

7. Then implement pipelines

Example:

ls | grep minishell | wc -l

You need:

pipe 1          pipe 2
┌───────┐      ┌───────┐
ls  → grep → wc

For each pipe:

pipe(fd);

Then connect processes using dup2():

Command 1 stdout → pipe write end
Command 2 stdin  ← pipe read end

Your executor should eventually look conceptually like:

for each command:
    create pipe if needed
    fork


    child:
        connect previous pipe to stdin
        connect current pipe to stdout
        apply redirections
        close unused fds
        execute builtin or execve


    parent:
        close unused pipe fds


wait for all children

A very important rule: close file descriptors you don't need, otherwise pipelines can hang.

8. I would organize your code like this
src/
├── execution/
│   ├── execute.c
│   ├── execute_external.c
│   ├── pipeline.c
│   ├── redirections.c
│   ├── command_path.c
│   └── wait_processes.c
│
├── builtins/
│   ├── builtin.c
│   ├── echo.c
│   ├── cd.c
│   ├── pwd.c
│   ├── export.c
│   ├── unset.c
│   ├── env.c
│   └── exit.c
│
└── environment/
    ├── env_utils.c
    └── env_update.c

This will make debugging much easier than having one huge execution.c.

9. Your recommended implementation order

I'd personally follow this exact order:

 Agree with your partner on the parser → executor data structure
 Create a global t_shell state structure
 Implement pwd
 Implement echo
 Implement env
 Implement one external command with fork + execve
 Implement $PATH lookup
 Implement waiting and exit statuses
 Implement cd
 Implement export
 Implement unset
 Implement exit
 Add output redirection >
 Add input redirection <
 Add append >>
 Add pipelines |
 Add heredoc handling
 Handle builtins differently inside/outside pipelines
 Test edge cases and file descriptor leaks
10. The biggest thing I can help you with

If you show me your project's current structs/header files, especially:

minishell.h
your token structure
the parser output / AST or command structure
your environment structure

I can help you design the executor around your actual codebase, step by step.

We can start with just the first milestone: take the parser output and execute ls, echo hello, and pwd correctly.

typedef struct s_redir
{
	t_redir_type	type;
	t_token			*target;
	int				heredoc_expand;
	int				heredoc_fd;
	struct s_redir	*next;
}	t_redir;

/*
** t_cmd
** Represents a single command in a pipeline.
** args   - linked list of tokens forming the command and its arguments
** redirs - linked list of redirections attached to this command
** next   - pointer to the next command in the pipeline (after a pipe)
*/
typedef struct s_cmd
{
	t_token			*args;
	t_redir			*redirs;
	struct s_cmd	*next;
}	t_cmd;

Perfect — this is enough to start designing your execution side. Your parser is giving you a linked list of commands, and each command has:

args → command + arguments as a linked list of tokens
redirs → redirections for that command
next → next command in a pipeline

So for:

cat < input.txt | grep hello > output.txt

you likely have:

t_cmd
│
├── args: ["cat"]
├── redirs: [< input.txt]
│
└── next
    │
    ├── args: ["grep", "hello"]
    ├── redirs: [> output.txt]
    │
    └── next: NULL
Your first job: understand t_token

Before writing execution, I need to see:

typedef struct s_token
{
    ...
}   t_token;

Especially, I need to know what field contains the actual string. For example, is it:

token->value

or:

token->str

or something else?

That matters because your executor will need to convert:

t_token linked list

into:

char **argv;

Because execve() requires:

execve(path, argv, envp);

For example:

args linked list:
"echo" -> "hello" -> "world"

needs to become:

argv[0] = "echo";
argv[1] = "hello";
argv[2] = "world";
argv[3] = NULL;
I would build your executor around these functions
int     execute_pipeline(t_shell *shell, t_cmd *cmds);
int     execute_command(t_shell *shell, t_cmd *cmd);
int     setup_redirections(t_shell *shell, t_redir *redirs);
char    **tokens_to_argv(t_token *args);
int     is_builtin(char *cmd);
int     execute_builtin(t_shell *shell, char **argv);
char    *find_command_path(char *cmd, char **envp);

The exact t_shell structure can change based on your project.

Step 1: Convert args into argv

This should probably be one of the first functions you implement.

Conceptually:

char    **tokens_to_argv(t_token *args)
{
    int     count;
    char    **argv;
    int     i;


    count = token_count(args);
    argv = malloc(sizeof(char *) * (count + 1));
    if (!argv)
        return (NULL);
    i = 0;
    while (args)
    {
        argv[i] = ft_strdup(args->value);
        if (!argv[i])
        {
            // free previous strings
            return (NULL);
        }
        i++;
        args = args->next;
    }
    argv[i] = NULL;
    return (argv);
}

You'll replace args->value with whatever your actual token string field is.

Important

If your expansion phase already removed quotes and expanded variables, then execution should receive the final strings.

For example:

echo "$USER"

should ideally already reach the executor as something like:

args -> "echo" -> "your_username"

The executor shouldn't be responsible for quote parsing.

Step 2: Count how many commands are in the pipeline

You'll need this:

int count_commands(t_cmd *cmds)
{
    int count;


    count = 0;
    while (cmds)
    {
        count++;
        cmds = cmds->next;
    }
    return (count);
}

You can use this to detect:

cmd->next == NULL

which means there's no pipeline.

This is especially important for builtins.

Step 3: Redirections should be applied in the correct order

Your t_redir is actually a nice structure:

typedef struct s_redir
{
    t_redir_type    type;
    t_token         *target;
    int             heredoc_expand;
    int             heredoc_fd;
    struct s_redir  *next;
}   t_redir;

This means your executor can simply walk through:

redir = cmd->redirs;
while (redir)
{
    // Apply this redirection
    redir = redir->next;
}

For each type:

REDIR_IN       < file
REDIR_OUT      > file
REDIR_APPEND   >> file
REDIR_HEREDOC  << delimiter

I need to see your actual:

typedef enum e_redir_type
{
    ...
}   t_redir_type;

before giving you exact code, because I don't want to guess the enum names.

But your function will probably look like:

int setup_redirections(t_redir *redirs)
{
    int fd;


    while (redirs)
    {
        if (redirs->type == REDIR_IN)
        {
            fd = open(redirs->target->value, O_RDONLY);
            if (fd < 0)
                return (error);
            dup2(fd, STDIN_FILENO);
            close(fd);
        }
        else if (redirs->type == REDIR_OUT)
        {
            fd = open(...);
            dup2(fd, STDOUT_FILENO);
            close(fd);
        }
        // append...
        // heredoc...
        redirs = redirs->next;
    }
    return (0);
}
Order matters

For:

echo hello > a > b

you must process them from left to right:

Open a, redirect stdout to a
Open b, redirect stdout to b

Final output goes to b, but a still gets created/truncated.

Your linked-list order should preserve the original command order.

Step 4: Handle a single builtin in the parent

This is the first major execution decision.

For:

export HELLO=world

you want:

main shell process
    ↓
execute_builtin()
    ↓
environment is permanently modified

Not:

main shell
    ↓
fork
    ↓
child runs export
    ↓
child exits
    ↓
changes are lost ❌

So your top-level logic can eventually be:

if (cmd->next == NULL && cmd->args && is_builtin(cmd->args))
{
    execute_builtin_in_parent(shell, cmd);
}
else
{
    execute_pipeline(shell, cmd);
}

Of course, is_builtin will probably receive the first argument string after you convert to argv.

Step 5: Your main execution architecture

Given your structs, I would structure it like this:

execute()
│
├── Is there only one command?
│   │
│   ├── YES
│   │   │
│   │   ├── Is it a builtin?
│   │   │   │
│   │   │   └── YES → run in parent
│   │   │
│   │   └── NO → fork → child executes external command
│   │
│   └── NO (pipeline)
│       │
│       └── execute_pipeline()
│
└── update shell exit status

And inside a pipeline:

for each t_cmd
    │
    ├── create pipe if there is a next command
    │
    ├── fork
    │
    ├── CHILD
    │   ├── connect previous pipe to stdin
    │   ├── connect current pipe to stdout
    │   ├── apply command redirections
    │   ├── close unused fds
    │   ├── convert args → argv
    │   └── builtin OR execve
    │
    └── PARENT
        └── close unused fds
Step 6: A key detail — redirections override pipes

Consider:

echo hello > file | wc -c

The command's stdout is first conceptually connected to the pipe, but its explicit:

> file

should override stdout.

So in the child, the safest general order is:

1. Set up pipeline stdin/stdout
2. Apply redirections in command order
3. Execute

Because the later dup2() calls from redirections replace the pipe connection.

Likewise:

cat < file | grep hello

The input redirection overrides the normal stdin.

So:

setup_pipe_fds(...);
setup_redirections(cmd->redirs);

is a good model.

What I need from you next

Send me these three definitions:

typedef struct s_token
{
    ...
}   t_token;
typedef enum e_redir_type
{
    ...
}   t_redir_type;

And your shell/environment struct, something like:

typedef struct s_shell
{
    ...
}   t_shell;

Once I see those, I can help you build the actual execution module for your project's structs, starting with:

tokens_to_argv()
builtin detection
redirection setup
single-command execution
the pipeline executor

We can go file by file, rather than jumping into one huge executor all at once.
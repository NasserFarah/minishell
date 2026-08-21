The problem

When PATH is unset (or set to an empty string) and you run a bare command like ls, your minishell always printed:

minishell: ls: command not found

That's the message bash uses when it searches PATH directories and finds nothing. But bash treats a missing/empty PATH differently: it skips the directory search entirely and tries to run the command name as-is (relative to the current directory). That almost always fails, but with a different, more accurate message:

bash: ls: No such file or directory

Both give exit code 127, so the shell "worked," but the message was wrong — which matters for minishell testers that diff output against real bash.

While verifying the fix, I found the same root issue affecting a couple of related cases:
- A missing file given with a slash (/bin/doesnotexist) also wrongly said "command not found" instead of "No such file or directory".
- The code that runs after a failed execve() was hardcoded to always exit 126 with a generic perror, regardless of why exec actually failed (missing file vs. permission denied vs. a d

What I fixed

src/execution/path.c — re
- If PATH is unset or empty, return the bare command name instead of declaring
"not found" up front, so nd fails naturally with the right error.
- Same treatment for slas — let execve() fail on its own rather than pre-checking with access().

src/execution/child.c — added an exec_fail() helper that inspects errno after a failed execve():
- ENOENT → No such file or directory, exit 127
- EACCES → Permission den
- target is a directory (checked via stat(), since Linux's execve reports EACCES
for directories, not EISD6

I verified all of these s (unset PATH, empty PATH,missing absolute path, permission-denied file, directory-as-command) and confirmed normal command ltins are unaffected.
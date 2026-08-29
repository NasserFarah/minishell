# Linked Lists and Trees — what you need for this project

You already have four linked lists in this codebase and you're about to
need your first tree (for step 9's `&&`/`||`/`()`). This explains both
data structures using your *actual* structs, not toy examples.

---

## Part 1 — Linked Lists

### The core idea

An array lives in one contiguous block of memory: `arr[0]`, `arr[1]`,
`arr[2]`... back to back. To have 5 elements you must know you need 5
slots up front (or realloc and copy everything when you don't).

A linked list solves "I don't know how many I'll need" differently: each
element is its own separate `malloc`, and each element stores a pointer
to the *next* element. The elements can be scattered anywhere in memory
— what makes them "a list" is purely that each one points to the next
one.

```
[node A] -> [node B] -> [node C] -> NULL
```

You never hold "the list" as one object. You hold a pointer to the
**first** node (the "head"). To get anywhere else, you follow `->next`
pointers one at a time. There is no `list[2]` — to reach the third node
you must walk through the first two.

That's it. That's the whole idea. Everything else is variations on
"struct with a pointer to the same struct type."

### Why your project uses them

You don't know ahead of time:
- how many environment variables `envp` has,
- how many tokens a command line produces,
- how many redirections one command has,
- how many commands a pipeline has (`a | b | c | d`).

A linked list grows one `malloc` at a time as you discover you need
another node — no upfront size, no resizing an array.

### Your actual linked lists

Look at `inc/structs.h`. You have **four** of them already:

```c
typedef struct s_env
{
    char            *key;
    char            *value;
    struct s_env    *next;
}   t_env;
```
One node per environment variable (`PATH`, `HOME`, ...). Built once at
startup from `envp` in `src/env/env.c`.

```c
typedef struct s_token
{
    t_token_type    type;
    char            *value;
    int             single_quoted;
    int             double_quoted;
    int             join_next;
    struct s_token  *next;
}   t_token;
```
One node per token the tokenizer produces (`echo`, `"Hello, "`, `|`,
`>>`, ...). Built by `tokenize()` in `src/tokenizer/`.

```c
typedef struct s_redir
{
    t_redir_type    type;
    t_token         *target;
    int             heredoc_expand;
    int             heredoc_fd;
    struct s_redir  *next;
}   t_redir;
```
One node per redirection a single command has (`cmd < a > b >> c` has
three). Note `target` is itself a pointer *into* the token list, not a
copy — this redir node is just pointing at the filename token.

```c
typedef struct s_cmd
{
    t_token         *args;
    t_redir         *redirs;
    struct s_cmd    *next;
}   t_cmd;
```
One node per pipeline stage. `cat file | grep foo | wc -l` is three
`t_cmd` nodes chained by `->next`, and **each one of those nodes owns its
own separate `t_token` list** (its args) **and its own `t_redir` list**
(its redirections). This is a linked list of nodes, where each node
*itself contains* two more linked lists. Structs nesting other linked
lists inside them is completely normal — don't let it look scarier than
it is.

```
t_cmd(cat) -> t_cmd(grep) -> t_cmd(wc) -> NULL
   |args: "cat","file"       |args: "grep","foo"   |args: "wc","-l"
   |redirs: NULL             |redirs: NULL         |redirs: NULL
```

### The three operations you keep re-implementing

Every linked list in your project needs the same three things. You've
already written all of them (in `tokenizer_utils.c`, `env.c`,
`parser_utils.c`, etc.) — recognizing the pattern helps you write the
*next* one faster.

**1. Append to the tail** (add a new node at the end, preserving order —
this is why token order and pipeline order come out correct):
```c
static void add_token_back(t_token **head, t_token *new)
{
    t_token *cur;

    if (!*head)
    {
        *head = new;
        return;
    }
    cur = *head;
    while (cur->next)
        cur = cur->next;
    cur->next = new;
}
```
This is `add_token_back` in your parser code — the exact shape shown
above. Notice the double pointer `t_token **head`: you need it because if
the list is empty, you must *modify the caller's head pointer itself*,
not just a local copy of it. This is the single most common bug source
in linked-list code in C — forgetting the list might be empty and
crashing on `cur->next` when `cur` is `NULL`, or forgetting the `**` and
having your append silently do nothing on an empty list.

**2. Traverse** (walk every node, doing something at each):
```c
t_token *cur = tokens;
while (cur)
{
    // do something with cur
    cur = cur->next;
}
```
This is how `debug_print_tokens` works, how expansion walks each arg,
how execution walks each pipeline stage.

**3. Free** (walk the list, freeing each node — but you must save
`->next` *before* freeing the current node, or you lose your only way to
reach the rest of the list):
```c
void free_tokens(t_token *tokens)
{
    t_token *next;

    while (tokens)
    {
        next = tokens->next;
        free(tokens->value);
        free(tokens);
        tokens = next;
    }
}
```
Your `t_cmd` free (`free_cmd`) has to do this *and* also call
`free_tokens`/free-the-redirs at each node, because each `t_cmd` node
owns two more lists. Freeing nested linked lists is always "free the
inner stuff first, then free the outer node," applied recursively down
through however many levels you have.

### Linked list vs. array, concretely

| | Array | Linked list |
|---|---|---|
| Access element N | instant (`arr[n]`) | must walk from head, N steps |
| Insert/remove in middle | shift everything after it | just relink two pointers |
| Size known ahead of time? | must decide upfront (or realloc) | grows one node at a time |
| Memory layout | one contiguous block | scattered, connected by pointers |

You use linked lists here specifically because you're building the list
one token/env-var/command *as you discover it exists*, and you never need
"give me element 7 directly" — you only ever need "give me all of them,
in order."

---

## Part 2 — Trees

### The core idea

A linked list is **linear**: every node has exactly one "next." A tree is
**hierarchical**: a node can have multiple children, and those children
can each have their own children. There's one node with no parent (the
**root**), and nodes with no children are **leaves**.

```
          root
         /    \
      child   child
       / \       \
    leaf leaf    leaf
```

In C, a tree node is a struct that holds pointers to its *children*
(other nodes of the same struct type), instead of one pointer to "next."

### Why your project is about to need one

Right now your pipeline structure (`t_cmd`, linked list) can only express
"do these commands in a pipe, left to right." That's genuinely all steps
1–8 need. But step 9 adds `&&`, `||`, and `(...)`, and a flat list cannot
represent what those mean.

Consider:
```
cmd1 && cmd2 || cmd3
```
This is not "run three things in some order." It means: run `cmd1`; if
it succeeded, run `cmd2`; if *that whole thing* (the `&&` combination)
failed, run `cmd3`. And parentheses can change what groups with what:
```
cmd1 && (cmd2 || cmd3)
```
now means something different from
```
(cmd1 && cmd2) || cmd3
```
There is no way to encode "which operator applies to which sub-group,
with what precedence" in a flat `next`-chain. You need nesting — a tree,
usually called an **AST** (Abstract Syntax Tree) in this context. That's
exactly what your `PROGRESS.md` flags for step 9: pipelines become the
**leaves**, and `AND`/`OR` become **internal nodes**, with parens simply
controlling how deep the nesting goes.

`cmd1 && cmd2 || cmd3` (`&&`/`||` same precedence, left-to-right in bash)
becomes:
```
              OR
             /  \
          AND   cmd3
         /   \
      cmd1   cmd2
```
`cmd1 && (cmd2 || cmd3)` becomes:
```
         AND
        /   \
     cmd1    OR
            /  \
         cmd2  cmd3
```
Same three commands, same two operators — different tree shape, different
behavior. That's the entire reason a tree is required here and a list
isn't: **the tree's shape *is* the grouping/precedence information**. A
list has no shape to encode that in.

### What the struct will look like

You haven't written this yet — per `CLAUDE.md` you should design your own
naming, not copy `friend_minishell` verbatim — but structurally, any
version of this will need the same three things a tree node always needs:
what kind of node it is, and pointers to its children:

```c
typedef enum e_node_type
{
    NODE_PIPELINE,   // a leaf: points at an existing t_cmd chain
    NODE_AND,        // internal: && of left and right
    NODE_OR,         // internal: || of left and right
}   t_node_type;

typedef struct s_node
{
    t_node_type     type;
    t_cmd           *pipeline;      // only used when type == NODE_PIPELINE
    struct s_node   *left;          // only used for AND/OR
    struct s_node   *right;         // only used for AND/OR
}   t_node;
```

Compare this to `t_token`/`t_env`/`t_cmd`: those had **one** `next`
pointer (linear). This has **two** child pointers, `left` and `right`
(hierarchical) — that's the entire structural difference between a
linked list and a (binary) tree. A leaf node (`NODE_PIPELINE`) is just a
node whose children are both `NULL` and which reuses your *existing*
`t_cmd` linked list to hold the actual pipeline. You don't throw away
what you built — the tree sits *on top of* it.

### Traversal is recursive, not a `while` loop

Walking a linked list is a `while (cur) { ...; cur = cur->next; }` loop —
one path, one direction. Walking a tree needs **recursion**, because at
each node you may need to go down two different paths (left, then
right), and each of those is itself a tree with the same shape as the
one you started with. That self-similarity — "a tree's child is itself a
tree" — is why recursion fits trees so naturally.

Execution of your AST will look roughly like this, and it's worth
noticing the shape maps directly onto bash's actual short-circuit
behavior:

```c
int exec_node(t_shell *shell, t_node *node)
{
    int status;

    if (node->type == NODE_PIPELINE)
        return (exec_pipeline(shell, node->pipeline)); // your existing step-7 code

    status = exec_node(shell, node->left);       // recurse left first
    if (node->type == NODE_AND && status != 0)
        return (status);                          // && short-circuits on failure
    if (node->type == NODE_OR && status == 0)
        return (status);                          // || short-circuits on success
    return (exec_node(shell, node->right));       // recurse right
}
```
`exec_node` calling itself on `node->left` and `node->right` *is* the
tree traversal — there's no explicit "list of nodes to visit," the call
stack does that bookkeeping for you. This also directly implements
`&&`/`||` short-circuiting: you literally don't call `exec_node` on the
right side at all when the left side already decided the outcome.

Freeing a tree follows the same recursive shape as freeing your nested
linked lists, just with two branches instead of one:
```c
void free_node(t_node *node)
{
    if (!node)
        return;
    if (node->type == NODE_PIPELINE)
        free_cmd(node->pipeline);   // reuse your existing list-free
    else
    {
        free_node(node->left);
        free_node(node->right);
    }
    free(node);
}
```
Free the children first, then free yourself — same "inner before outer"
rule as your nested `t_cmd`/`t_token`/`t_redir` free, just branching in
two directions instead of one.

### Linked list vs. tree, side by side

| | Linked list (what you have) | Tree (what step 9 needs) |
|---|---|---|
| Pointers per node | one (`next`) | multiple (`left`/`right`, or a children list) |
| Shape | a straight line | branches out, has depth |
| Natural walk | `while` loop | recursive function |
| What it encodes | **order** (this comes before that) | **structure/precedence** (this groups with that) |
| Example in your code | `t_token`, `t_cmd` pipeline chain | the upcoming `t_node` AST |

### The one-sentence summary to keep in your head

- **Linked list**: "these things happen in this order" — one `next` per
  node, walked with a loop.
- **Tree**: "these things are grouped like *this*, and the grouping
  changes the meaning" — multiple children per node, walked with
  recursion, and the tree's *shape itself* is the information (which is
  exactly what `&&`/`||`/`()` precedence needs and a flat list can't
  express).

Everything else — parser grammar rules, precedence climbing, how
parentheses adjust nesting depth — is detail on top of that one
structural idea.

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   minishell.h                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:36:02 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:36:04 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

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

extern volatile sig_atomic_t	g_signal;

// shell
void		shell_loop(t_shell *shell);
void		free_shell(t_shell *shell);

// signals
void		init_signals(void);
void		signals_ignore_during_exec(void);
void		signals_child_default(void);

// env
t_env		*env_init(char **envp);
void		free_env(t_env *env);
char		*env_get(t_env *env, const char *key);
void		env_set(t_env **env, const char *key, const char *value);
void		env_unset(t_env **env, const char *key);

// tokenizer
t_token		*tokenize(const char *line);
t_token		*new_token(t_token_type type, char *value);
t_token		*make_word_token(const char *line, int *i, int *error);
void		add_token_back(t_token **head, t_token *new);
void		free_tokens(t_token *tokens);
int			is_operator_char(char c);
int			validate_tokens(t_token *tokens);
void		print_syntax_error(t_token *near);

// parser
t_cmd		*parse(t_token **tokens);
t_cmd		*new_cmd(void);
t_token		*take_word(t_token **tokens);
int			consume_redir(t_token **tokens, t_redir **redirs);
void		free_cmd(t_cmd *cmd);

// expansion
void		expand(t_shell *shell);
char		*expand_fragment(const char *value, t_shell *shell);
void		expand_fragments(t_token *word, t_shell *shell);
t_token		*split_word(t_token *word);
char		*join_word(t_token *word);
void		expand_cmd_redirs(t_cmd *cmd, t_shell *shell);

// execution
void		execute(t_shell *shell);
char		*resolve_executable(const char *cmd, t_env *env, int *exit_code);
char		**build_argv(t_token *args);
char		**build_envp(t_env *env);
int			apply_redirs(t_redir *redirs);
void		resolve_heredocs(t_shell *shell);
void		close_heredoc_fds(t_cmd *ast);
t_pipeline	*build_pipeline(int n_cmds);
void		wire_pipes(t_pipeline *pl, int idx);
void		close_pipes(t_pipeline *pl);
void		free_pipeline(t_pipeline *pl);
void		run_child(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx);
int			wait_all(t_pipeline *pl);
int			run_standalone_builtin(t_cmd *cmd, t_shell *shell);

// builtin_functions
int			is_builtin(const char *name);
int			run_builtin(t_cmd *cmd, t_shell *shell);
int			is_valid_name(const char *s);
int			builtin_echo(t_cmd *cmd, t_shell *shell);
int			builtin_pwd(t_cmd *cmd, t_shell *shell);
int			builtin_cd(t_cmd *cmd, t_shell *shell);
int			builtin_env(t_cmd *cmd, t_shell *shell);
int			builtin_export(t_cmd *cmd, t_shell *shell);
void		print_export(t_env *env);
int			builtin_unset(t_cmd *cmd, t_shell *shell);
int			builtin_exit(t_cmd *cmd, t_shell *shell);

#endif

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   structs.h                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 22:43:27 by abdunass          #+#    #+#             */
/*   Updated: 2026/07/27 22:43:27 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef STRUCTS_H
# define STRUCTS_H

typedef struct s_env
{
	char			*key;
	char			*value;
	struct s_env	*next;
}	t_env;

typedef enum e_token_type
{
	TOKEN_WORD,
	TOKEN_PIPE,
	TOKEN_REDIR_IN,
	TOKEN_REDIR_OUT,
	TOKEN_REDIR_APPEND,
	TOKEN_HEREDOC
}	t_token_type;

typedef struct s_token
{
	t_token_type	type;
	char			*value;
	int				single_quoted;
	int				double_quoted;
	int				join_next;
	struct s_token	*next;
}	t_token;

typedef enum e_redir_type
{
	REDIR_IN,
	REDIR_OUT,
	REDIR_APPEND,
	REDIR_HEREDOC
}	t_redir_type;

typedef struct s_redir
{
	t_redir_type	type;
	t_token			*target;
	int				heredoc_expand;
	int				heredoc_fd;
	struct s_redir	*next;
}	t_redir;

typedef struct s_cmd
{
	t_token			*args;
	t_redir			*redirs;
	struct s_cmd	*next;
}	t_cmd;

typedef struct s_shell
{
	t_env	*env;
	int		exit_status;
	int		interactive;
	int		should_exit;
	t_token	*tokens;
	t_cmd	*pipeline;
}	t_shell;

typedef struct s_split
{
	char	*acc;
	int		touched;
	t_token	*out;
}	t_split;

typedef struct s_pipeline
{
	int		n_cmds;
	int		*pipes;
	pid_t	*pids;
}	t_pipeline;

#endif

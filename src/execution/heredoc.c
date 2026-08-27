/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   heredoc.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/27 20:35:15 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/27 20:35:20 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	resolve(const char *delim, int want_expand, t_shell *shell)
{
	int		pipefd[2];
	char	*line;

	if (pipe(pipefd) == -1)
		return (-1);
	while (1)
	{
		line = heredoc_line();
		if (!line)
		{
			if (g_signal == SIGINT)
				return (close(pipefd[0]), close(pipefd[1]), -1);
			warn_eof(delim);
			break ;
		}
		if (is_delim(line, delim))
			return (free(line), close(pipefd[1]), pipefd[0]);
		write_line(pipefd[1], line, want_expand, shell);
		free(line);
	}
	close(pipefd[1]);
	return (pipefd[0]);
}

static int	resolve_cmd_heredocs(t_cmd *cmd, t_shell *shell)
{
	t_redir	*redir;

	redir = cmd->redirs;
	while (redir)
	{
		if (redir->type == REDIR_HEREDOC)
		{
			redir->heredoc_fd = resolve(redir->target->value,
					redir->heredoc_expand, shell);
			if (redir->heredoc_fd == -1)
				return (-1);
		}
		redir = redir->next;
	}
	return (0);
}

int	resolve_heredocs(t_shell *shell)
{
	t_cmd	*cmd;
	int		status;

	g_signal = 0;
	init_signals_heredoc();
	status = 0;
	cmd = shell->pipeline;
	while (cmd && status == 0)
	{
		status = resolve_cmd_heredocs(cmd, shell);
		cmd = cmd->next;
	}
	init_signals();
	return (status);
}

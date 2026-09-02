/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   heredoc.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/27 20:35:15 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/28 03:53:51 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	fill_heredoc(int fd, const char *delim, int want_expand,
		t_shell *shell)
{
	char	*line;

	while (1)
	{
		line = heredoc_line();
		if (!line)
		{
			if (g_signal == SIGINT)
				return (-1);
			warn_eof(delim);
			return (0);
		}
		if (is_delim(line, delim))
			return (free(line), 0);
		write_line(fd, line, want_expand, shell);
		free(line);
	}
}

static int	resolve(const char *delim, int want_expand, t_shell *shell)
{
	char	path[64];
	int		fd;

	fd = open_heredoc_file(path, sizeof(path));
	if (fd == -1)
		return (-1);
	if (fill_heredoc(fd, delim, want_expand, shell) == -1)
		return (close(fd), unlink(path), -1);
	close(fd);
	fd = open(path, O_RDONLY);
	unlink(path);
	return (fd);
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

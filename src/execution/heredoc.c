/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   heredoc.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

#define HEREDOC_TMP "/tmp/.minishell_heredoc"

static int	is_delim(const char *line, const char *delim)
{
	return (ft_strlen(line) == ft_strlen(delim)
		&& ft_strncmp(line, delim, ft_strlen(delim) + 1) == 0);
}

// static void	write_line(int fd, char *line, int want_expand, t_shell *shell)
// {
// 	char	*out;

// 	if (want_expand)
// 		out = expand_fragment(line, shell);
// 	else
// 		out = ft_strdup(line);
// 	write(fd, out, ft_strlen(out));
// 	write(fd, "\n", 1);
// 	free(out);
// }

static int	heredoc_body(const char *delim, int want_expand, t_shell *shell)
{
	int		red;
	char	*line;

	// fd = open(HEREDOC_TMP, O_CREAT | O_WRONLY | O_TRUNC, 0600);
	// if (fd == -1)
	// 	return (-1);
	// line = readline("> ");
	// while (line && !is_delim(line, delim))
	// {
	// 	write_line(fd, line, want_expand, shell);
	// 	free(line);
	// 	line = readline("> ");
	// }
	// free(line);
	// close(fd);
	// fd = open(HEREDOC_TMP, O_RDONLY);
	// unlink(HEREDOC_TMP);
	(void)want_expand;
	(void)shell;
	line = malloc(2048 * sizeof(line));
	if (!line)
		return (-1);
	while (line && !is_delim(line, delim))
	{
		write(0, ">", 1);
		red = read(STDIN_FILENO, line, 2048);
		if (red <= 0)
			break ;
	}
	return (red);
}

static void	resolve_cmd_heredocs(t_cmd *cmd, t_shell *shell)
{
	t_redir	*redir;

	redir = cmd->redirs;
	while (redir)
	{
		if (redir->type == REDIR_HEREDOC)
			heredoc_body(redir->target->value, redir->heredoc_expand, shell);
		redir = redir->next;
	}
}

void	resolve_heredocs(t_shell *shell)
{
	t_cmd	*cmd;

	cmd = shell->pipeline;
	while (cmd)
	{
		resolve_cmd_heredocs(cmd, shell);
		cmd = cmd->next;
	}
}

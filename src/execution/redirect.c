/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   redirect.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	redir_flags(t_redir_type type)
{
	if (type == REDIR_IN)
		return (O_RDONLY);
	if (type == REDIR_APPEND)
		return (O_WRONLY | O_CREAT | O_APPEND);
	return (O_WRONLY | O_CREAT | O_TRUNC);
}

static int	ambiguous_redirect(t_redir *redir)
{
	ft_putstr_fd((char *)redir->target->value, STDERR_FILENO);
	ft_putstr_fd(": ambiguous redirect\n", STDERR_FILENO);
	return (-1);
}

static int	apply_one_redir(t_redir *redir)
{
	int	fd;

	if (redir->type == REDIR_HEREDOC)
	{
		dup2(redir->heredoc_fd, STDIN_FILENO);
		close(redir->heredoc_fd);
		return (0);
	}
	if (redir->ambiguous)
		return (ambiguous_redirect(redir));
	fd = open(redir->target->value, redir_flags(redir->type), 0644);
	if (fd == -1)
	{
		perror(redir->target->value);
		return (-1);
	}
	if (redir->type == REDIR_IN)
		dup2(fd, STDIN_FILENO);
	else
		dup2(fd, STDOUT_FILENO);
	close(fd);
	return (0);
}

int	apply_redirs(t_redir *redirs)
{
	while (redirs)
	{
		if (apply_one_redir(redirs) == -1)
			return (-1);
		redirs = redirs->next;
	}
	return (0);
}

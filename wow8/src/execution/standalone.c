/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   standalone.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:31:17 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:31:23 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	save_fd(int fd)
{
	return (dup(fd));
}

static void	restore_fd(int fd, int saved)
{
	dup2(saved, fd);
	close(saved);
}

int	run_standalone_builtin(t_cmd *cmd, t_shell *shell)
{
	int	saved_in;
	int	saved_out;
	int	status;

	saved_in = save_fd(STDIN_FILENO);
	saved_out = save_fd(STDOUT_FILENO);
	if (apply_redirs(cmd->redirs) == -1)
		status = 1;
	else
		status = run_builtin(cmd, shell);
	restore_fd(STDIN_FILENO, saved_in);
	restore_fd(STDOUT_FILENO, saved_out);
	return (status);
}

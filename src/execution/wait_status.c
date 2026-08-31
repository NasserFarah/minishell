/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   wait_status.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/28 03:54:37 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/28 03:54:40 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	last_status(int status)
{
	if (WIFSIGNALED(status))
	{
		if (WTERMSIG(status) == SIGINT)
			write(STDOUT_FILENO, "\n", 1);
		else if (WTERMSIG(status) == SIGQUIT)
			ft_putstr_fd("Quit (core dumped)\n", STDERR_FILENO);
		return (128 + WTERMSIG(status));
	}
	return (WEXITSTATUS(status));
}

int	wait_all(t_pipeline *pl)
{
	int	i;
	int	status;
	int	result;

	i = 0;
	result = 0;
	while (i < pl->n_cmds)
	{
		waitpid(pl->pids[i], &status, 0);
		if (i == pl->n_cmds - 1)
			result = last_status(status);
		i++;
	}
	return (result);
}

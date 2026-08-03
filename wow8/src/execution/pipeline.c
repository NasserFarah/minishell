/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   pipeline.c                                         :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:30:46 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:30:50 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static t_pipeline	*pipeline_fail(t_pipeline *pl)
{
	if (pl)
	{
		free(pl->pids);
		free(pl->pipes);
		free(pl);
	}
	return (NULL);
}

t_pipeline	*build_pipeline(int n_cmds)
{
	t_pipeline	*pl;
	int			i;

	pl = malloc(sizeof(t_pipeline));
	if (!pl)
		return (NULL);
	pl->n_cmds = n_cmds;
	pl->pids = malloc(sizeof(pid_t) * n_cmds);
	pl->pipes = malloc(sizeof(int) * 2 * (n_cmds - 1));
	if (!pl->pids || (n_cmds > 1 && !pl->pipes))
		return (pipeline_fail(pl));
	i = 0;
	while (i < n_cmds - 1)
	{
		if (pipe(pl->pipes + i * 2) == -1)
			return (pipeline_fail(pl));
		i++;
	}
	return (pl);
}

void	wire_pipes(t_pipeline *pl, int idx)
{
	if (idx > 0)
		dup2(pl->pipes[(idx - 1) * 2], STDIN_FILENO);
	if (idx < pl->n_cmds - 1)
		dup2(pl->pipes[idx * 2 + 1], STDOUT_FILENO);
}

void	close_pipes(t_pipeline *pl)
{
	int	i;

	i = 0;
	while (i < (pl->n_cmds - 1) * 2)
	{
		close(pl->pipes[i]);
		i++;
	}
}

void	free_pipeline(t_pipeline *pl)
{
	free(pl->pipes);
	free(pl->pids);
	free(pl);
}

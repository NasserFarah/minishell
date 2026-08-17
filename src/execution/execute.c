/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   execute.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	count_cmds(t_cmd *pipeline)
{
	int	n;

	n = 0;
	while (pipeline)
	{
		n++;
		pipeline = pipeline->next;
	}
	return (n);
}

static int	fork_cmd(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx)
{
	pid_t	pid;

	pid = fork();
	if (pid == -1)
	{
		perror("minishell: fork");
		return (-1);
	}
	if (pid == 0)
		run_child(cmd, shell, pl, idx);
	pl->pids[idx] = pid;
	return (0);
}

static void	fork_all(t_cmd *pipeline, t_shell *shell, t_pipeline *pl)
{
	int	i;

	i = 0;
	while (pipeline)
	{
		fork_cmd(pipeline, shell, pl, i);
		pipeline = pipeline->next;
		i++;
	}
}

void	close_heredoc_fds(t_cmd *pipeline)
{
	t_redir	*redir;

	while (pipeline)
	{
		redir = pipeline->redirs;
		while (redir)
		{
			if (redir->type == REDIR_HEREDOC && redir->heredoc_fd >= 0)
				close(redir->heredoc_fd);
			redir = redir->next;
		}
		pipeline = pipeline->next;
	}
}

void	execute(t_shell *shell)
{
	t_pipeline	*pl;

	resolve_heredocs(shell);
	if (shell->pipeline->args && !shell->pipeline->next
		&& is_builtin(shell->pipeline->args->value))
	{
		shell->exit_status = run_standalone_builtin(shell->pipeline, shell);
		close_heredoc_fds(shell->pipeline);
		return ;
	}
	pl = build_pipeline(count_cmds(shell->pipeline));
	if (!pl)
		return ;
	signals_ignore_during_exec();
	fork_all(shell->pipeline, shell, pl);
	close_pipes(pl);
	close_heredoc_fds(shell->pipeline);
	shell->exit_status = wait_all(pl);
	init_signals();
	free_pipeline(pl);
}

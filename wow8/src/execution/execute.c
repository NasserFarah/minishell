/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   execute.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:30:13 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:30:16 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	count_cmds(t_cmd *ast)
{
	int	n;

	n = 0;
	while (ast)
	{
		n++;
		ast = ast->next;
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

static void	fork_all(t_cmd *ast, t_shell *shell, t_pipeline *pl)
{
	int	i;

	i = 0;
	while (ast)
	{
		fork_cmd(ast, shell, pl, i);
		ast = ast->next;
		i++;
	}
}

void	close_heredoc_fds(t_cmd *ast)
{
	t_redir	*redir;

	while (ast)
	{
		redir = ast->redirs;
		while (redir)
		{
			if (redir->type == REDIR_HEREDOC && redir->heredoc_fd >= 0)
				close(redir->heredoc_fd);
			redir = redir->next;
		}
		ast = ast->next;
	}
}

void	execute(t_shell *shell)
{
	t_pipeline	*pl;

	resolve_heredocs(shell);
	if (shell->ast->args && !shell->ast->next
		&& is_builtin(shell->ast->args->value))
	{
		shell->exit_status = run_standalone_builtin(shell->ast, shell);
		close_heredoc_fds(shell->ast);
		return ;
	}
	pl = build_pipeline(count_cmds(shell->ast));
	if (!pl)
		return ;
	signals_ignore_during_exec();
	fork_all(shell->ast, shell, pl);
	close_pipes(pl);
	close_heredoc_fds(shell->ast);
	shell->exit_status = wait_all(pl);
	init_signals();
	free_pipeline(pl);
}

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/31 23:10:32 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:10:35 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	run_tokens(t_shell *shell)
{
	shell->pipeline = parse(&shell->tokens);
	if (shell->pipeline)
	{
		expand(shell);
		execute(shell);
	}
	free_cmd(shell->pipeline);
	shell->pipeline = NULL;
}

static void	process_line(t_shell *shell, char *line)
{
	int	tok_error;

	tok_error = 0;
	shell->tokens = tokenize(line, &tok_error);
	free(line);
	if (shell->tokens && !validate_tokens(shell->tokens))
	{
		shell->exit_status = 2;
		free_tokens(shell->tokens);
		shell->tokens = NULL;
	}
	else if (shell->tokens)
		run_tokens(shell);
	else if (tok_error)
		shell->exit_status = 2;
}

void	shell_loop(t_shell *shell)
{
	char	*line;
	char	prompt[4096];

	while (1)
	{
		g_signal = 0;
		if (shell->interactive)
			line = read_interactive_line(shell, prompt);
		else
			line = read_noninteractive_line();
		if (g_signal == SIGINT)
		{
			shell->exit_status = 130;
			g_signal = 0;
		}
		if (!line)
			break ;
		process_line(shell, line);
		if (shell->should_exit)
			break ;
	}
	rl_clear_history();
}

void	free_shell(t_shell *shell)
{
	free_env(shell->env);
	free(shell->cwd);
	get_next_line(-1);
}

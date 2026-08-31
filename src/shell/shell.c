/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 22:43:27 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/27 22:43:27 by abdunass       ###   ########.fr       */
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
			line = read_interactive_line(prompt);
		else
			line = read_noninteractive_line();
		if (g_signal == SIGINT)
		{
			shell->exit_status = 130;
			g_signal = 0;
		}
		if (!line)
			break ;
		if (ft_strlen(line) == 0)
			shell->exit_status = 0;
		process_line(shell, line);
		if (shell->should_exit)
			break ;
	}
	rl_clear_history();
}

void	free_shell(t_shell *shell)
{
	free_env(shell->env);
	get_next_line(-1);
}

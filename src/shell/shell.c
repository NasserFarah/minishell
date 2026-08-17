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

static void	process_line(t_shell *shell, char *line)
{
	shell->tokens = tokenize(line);
	free(line);
	if (shell->tokens && !validate_tokens(shell->tokens))
	{
		shell->exit_status = 2;
		free_tokens(shell->tokens);
		shell->tokens = NULL;
	}
	else if (shell->tokens)
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
}

void	shell_loop(t_shell *shell)
{
	char	*line;
	char	prompt[4096];

	while (1)
	{
		if (!getcwd(prompt, sizeof(prompt)))
			break ;
		ft_strlcat(prompt, "$ ", 4096);
		line = readline(prompt);
		if (!line)
		{
			ft_putstr_fd("exit\n", STDOUT_FILENO);
			break ;
		}
		if (*line)
			add_history(line);
		process_line(shell, line);
		if (shell->should_exit)
			break ;
	}
	rl_clear_history();
	clear_history();
	rl_free_line_state();
	rl_cleanup_after_signal();
}

void	free_shell(t_shell *shell)
{
	free_env(shell->env);
}

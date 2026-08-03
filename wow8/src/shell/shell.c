/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:33:57 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/31 00:12:07 by fnasser          ###   ########.fr       */
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
		shell->ast = parse(&shell->tokens);
		if (shell->ast)
		{
			expand(shell);
			execute(shell);
		}
		free_cmd(shell->ast);
		shell->ast = NULL;
	}
}

void	shell_loop(t_shell *shell)
{
	char	*line;

	while (1)
	{
		line = readline("minishell$ ");
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
}

void	free_shell(t_shell *shell)
{
	free_env(shell->env);
}

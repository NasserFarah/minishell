/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:33:08 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:33:12 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	init_shell(t_shell *shell, char **envp)
{
	shell->env = env_init(envp);
	shell->exit_status = 0;
	shell->interactive = isatty(STDIN_FILENO);
	shell->should_exit = 0;
}

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	(void)argv;
	init_shell(&shell, envp);
	init_signals();
	shell_loop(&shell);
	free_shell(&shell);
	return (shell.exit_status);
}

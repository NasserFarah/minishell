/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 22:43:27 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/27 22:43:27 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	shlvl(t_shell *shell)
{
	char	*shlvl;
	int		lvl;

	shlvl = env_get(shell->env, "SHLVL");
	if (!shlvl)
		lvl = 1;
	else
	{
		lvl = ft_atoi(shlvl);
		if (lvl < 0)
			lvl = 0;
		lvl++;
	}
	shlvl = ft_itoa(lvl);
	if (shlvl)
	{
		env_set(&shell->env, "SHLVL", shlvl);
		free(shlvl);
	}
}

static void	init_shell(t_shell *shell, char **argv, char **envp)
{
	static char	c[4096];

	shell->env = env_init(envp);
	env_set(&shell->env, "PWD", getcwd(c, 4096));
	env_set(&shell->env, "_", argv[0]);
	shell->exit_status = 0;
	shell->interactive = isatty(STDIN_FILENO);
	shell->should_exit = 0;
}

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	init_shell(&shell, argv, envp);
	shlvl(&shell);
	init_signals();
	shell_loop(&shell);
	free_shell(&shell);
	return (shell.exit_status);
}

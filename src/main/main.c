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

static void	art(void)
{
	printf("\n");
	printf("%s%s%s\n", PINK,
		"███╗   ███╗██╗███╗   ██╗██╗       ██╗  ██╗███████╗██╗\t  ██╗", RESET);
	printf("%s%s%s\n", PINK,
		"████╗ ████║██║████╗  ██║██║       ██║  ██║██╔════╝██║\t  ██║", RESET);
	printf("%s%s%s\n", PINK2,
		"██╔████╔██║██║██╔██╗ ██║██║ ████╗ ███████║█████╗  ██║\t  ██║", RESET);
	printf("%s%s%s\n", PINK,
		"██║╚██╔╝██║██║██║╚██╗██║██║ ╚═══╝ ██╔══██║██╔══╝  ██║\t  ██║", RESET);
	printf("%s%s%s\n", PINK,
		"██║ ╚═╝ ██║██║██║ ╚████║██║\t  ██║  ██║███████╗███████╗███████╗",
		RESET);
	printf("%s%s%s\n", PINK,
		"╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝",
		RESET);
	printf("%s%s%s\n", PINK2, "\t\t  Done by Abdullah && Farah", RESET);
	printf("\n");
	printf("%s    NO BASH WAS HARMED IN THE MAKING OF THIS SHELL!%s\n",
		PINK, RESET);
}

int	main(int argc, char **argv, char **envp)
{
	t_shell	shell;

	(void)argc;
	init_shell(&shell, argv, envp);
	shlvl(&shell);
	init_signals();
	if (shell.interactive)
		art();
	shell_loop(&shell);
	free_shell(&shell);
	return (shell.exit_status);
}

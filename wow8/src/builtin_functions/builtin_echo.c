/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_echo.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:26:57 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:27:02 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	is_echo_n_flag(const char *s)
{
	int	i;

	if (s[0] != '-' || s[1] != 'n')
		return (0);
	i = 1;
	while (s[i] == 'n')
		i++;
	return (s[i] == '\0');
}

int	builtin_echo(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;
	int		newline;

	(void)shell;
	arg = cmd->args->next;
	newline = 1;
	while (arg && is_echo_n_flag(arg->value))
	{
		newline = 0;
		arg = arg->next;
	}
	while (arg)
	{
		ft_putstr_fd(arg->value, STDOUT_FILENO);
		if (arg->next)
			ft_putchar_fd(' ', STDOUT_FILENO);
		arg = arg->next;
	}
	if (newline)
		ft_putchar_fd('\n', STDOUT_FILENO);
	return (0);
}

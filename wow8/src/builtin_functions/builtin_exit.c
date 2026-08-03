/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_exit.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:27:21 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:27:25 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	is_numeric(const char *s)
{
	int	i;

	i = 0;
	if (s[i] == '+' || s[i] == '-')
		i++;
	if (!s[i])
		return (0);
	while (s[i])
	{
		if (!ft_isdigit(s[i]))
			return (0);
		i++;
	}
	return (1);
}

static int	exit_code_mod256(const char *s)
{
	int	i;
	int	neg;
	int	val;

	i = 0;
	neg = 0;
	val = 0;
	if (s[i] == '+' || s[i] == '-')
	{
		neg = (s[i] == '-');
		i++;
	}
	while (s[i])
	{
		val = (val * 10 + (s[i] - '0')) % 256;
		i++;
	}
	if (neg)
		val = -val;
	return (((val % 256) + 256) % 256);
}

static int	non_numeric_exit(t_shell *shell, const char *arg)
{
	ft_putstr_fd("minishell: exit: ", STDERR_FILENO);
	ft_putstr_fd((char *)arg, STDERR_FILENO);
	ft_putstr_fd(": numeric argument required\n", STDERR_FILENO);
	shell->should_exit = 1;
	shell->exit_status = 255;
	return (255);
}

int	builtin_exit(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;

	ft_putendl_fd("exit", STDOUT_FILENO);
	arg = cmd->args->next;
	if (!arg)
	{
		shell->should_exit = 1;
		return (shell->exit_status);
	}
	if (arg->next)
	{
		ft_putstr_fd("minishell: exit: too many arguments\n", STDERR_FILENO);
		return (1);
	}
	if (!is_numeric(arg->value))
		return (non_numeric_exit(shell, arg->value));
	shell->should_exit = 1;
	shell->exit_status = exit_code_mod256(arg->value);
	return (shell->exit_status);
}

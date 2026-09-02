/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_exit.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:45:45 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/21 22:45:46 by fnasser          ###   ########.fr       */
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

static int	non_numeric_exit(t_shell *shell, const char *arg)
{
	ft_putstr_fd("minishell: exit: ", STDERR_FILENO);
	ft_putstr_fd((char *)arg, STDERR_FILENO);
	ft_putstr_fd(": numeric argument required\n", STDERR_FILENO);
	shell->should_exit = 1;
	shell->exit_status = 2;
	return (2);
}

static int	is_overflow(const char *digits, int digit_count, int neg)
{
	const char	*bound;

	if (digit_count > 19)
		return (1);
	if (digit_count < 19)
		return (0);
	if (neg)
		bound = "9223372036854775808";
	else
		bound = "9223372036854775807";
	return (ft_strncmp(digits, bound, 19) > 0);
}

static int	exit_code_mod(const char *s, t_shell *shell)
{
	int	i;
	int	j;
	int	neg;
	int	val;

	i = 0;
	neg = 0;
	val = 0;
	j = 0;
	if (s[i] == '+' || s[i] == '-')
	{
		j = 1;
		neg = (s[i] == '-');
		i++;
	}
	while (s[i])
	{
		val = (val * 10 + (s[i] - '0')) % 256;
		i++;
	}
	if (is_overflow(s + j, i - j, neg))
		return (non_numeric_exit(shell, s));
	if (neg)
		val = -val;
	return (((val % 256) + 256) % 256);
}

int	builtin_exit(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;

	ft_putendl_fd("exit", STDOUT_FILENO);
	arg = cmd->args->next;
	if (!arg)
	{
		shell->should_exit = 1;
		shell->exit_status = 0;
		return (shell->exit_status);
	}
	if (!is_numeric(arg->value))
		return (non_numeric_exit(shell, arg->value));
	if (arg->next)
	{
		ft_putstr_fd("minishell: exit: too many arguments\n", STDERR_FILENO);
		return (1);
	}
	shell->should_exit = 1;
	shell->exit_status = exit_code_mod(arg->value, shell);
	return (shell->exit_status);
}

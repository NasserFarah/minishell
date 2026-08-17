/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_export.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	export_one(t_shell *shell, const char *arg)
{
	char	*eq;
	char	*name;

	if (!is_valid_name(arg))
	{
		ft_putstr_fd("minishell: export: `", STDERR_FILENO);
		ft_putstr_fd((char *)arg, STDERR_FILENO);
		ft_putstr_fd("': not a valid identifier\n", STDERR_FILENO);
		return (0);
	}
	eq = ft_strchr(arg, '=');
	if (eq)
	{
		name = ft_substr(arg, 0, eq - arg);
		env_set(&shell->env, name, eq + 1);
		free(name);
	}
	else if (!env_get(shell->env, arg))
		env_set(&shell->env, arg, "");
	return (1);
}

int	builtin_export(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;
	int		status;

	arg = cmd->args->next;
	if (!arg)
	{
		print_export(shell->env);
		return (0);
	}
	status = 0;
	while (arg)
	{
		if (!export_one(shell, arg->value))
			status = 1;
		arg = arg->next;
	}
	return (status);
}

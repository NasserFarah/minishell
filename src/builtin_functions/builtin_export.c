/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_export.c                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:45:56 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/21 22:45:57 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

// special for export with no equal
static void	env_set_no_eq(t_env **env, const char *key)
{
	t_env	*cur;
	char	*value;

	cur = *env;
	value = NULL;
	while (cur)
	{
		if (cur->key && ft_strncmp(cur->key, key, ft_strlen(key) + 1) == 0)
		{
			return ;
		}
		cur = cur->next;
	}
	env_append_new(env, key, value);
}

static int	export_append(t_shell *shell, const char *name, const char *value)
{
	char	*old;
	char	*joined;

	if (!is_valid_name(name))
		return (0);
	old = env_get(shell->env, name);
	if (old)
		joined = ft_strjoin(old, value);
	else
		joined = ft_strdup(value);
	env_set(&shell->env, name, joined);
	free(joined);
	return (1);
}

static int	try_append(t_shell *shell, const char *arg, char *eq)
{
	char	*name;
	int		ok;

	name = ft_substr(arg, 0, eq - arg - 1);
	ok = export_append(shell, name, eq + 1);
	free(name);
	return (ok);
}

static int	export_one(t_shell *shell, const char *arg)
{
	char	*eq;
	char	*name;

	eq = ft_strchr(arg, '=');
	if (eq && eq > arg && eq[-1] == '+' && try_append(shell, arg, eq))
		return (1);
	if (!is_valid_name(arg))
	{
		ft_putstr_fd("minishell: export: `", STDERR_FILENO);
		ft_putstr_fd((char *)arg, STDERR_FILENO);
		ft_putstr_fd("': not a valid identifier\n", STDERR_FILENO);
		return (0);
	}
	if (eq)
	{
		name = ft_substr(arg, 0, eq - arg);
		env_set(&shell->env, name, eq + 1);
		free(name);
	}
	else if (!env_get(shell->env, arg))
		env_set_no_eq(&shell->env, arg);
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

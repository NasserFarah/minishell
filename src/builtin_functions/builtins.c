/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtins.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

int	is_builtin(const char *name)
{
	return (ft_strncmp(name, "echo", 5) == 0
		|| ft_strncmp(name, "cd", 3) == 0
		|| ft_strncmp(name, "pwd", 4) == 0
		|| ft_strncmp(name, "export", 7) == 0
		|| ft_strncmp(name, "unset", 6) == 0
		|| ft_strncmp(name, "env", 4) == 0
		|| ft_strncmp(name, "exit", 5) == 0);
}

int	run_builtin(t_cmd *cmd, t_shell *shell)
{
	char	*name;

	name = cmd->args->value;
	if (ft_strncmp(name, "echo", 5) == 0)
		return (builtin_echo(cmd, shell));
	if (ft_strncmp(name, "cd", 3) == 0)
		return (builtin_cd(cmd, shell));
	if (ft_strncmp(name, "pwd", 4) == 0)
		return (builtin_pwd(cmd, shell));
	if (ft_strncmp(name, "export", 7) == 0)
		return (builtin_export(cmd, shell));
	if (ft_strncmp(name, "unset", 6) == 0)
		return (builtin_unset(cmd, shell));
	if (ft_strncmp(name, "env", 4) == 0)
		return (builtin_env(cmd, shell));
	return (builtin_exit(cmd, shell));
}

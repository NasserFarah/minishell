/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_cd.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	update_pwd(t_shell *shell, char *oldpwd)
{
	char	newpwd[4096];

	if (getcwd(newpwd, sizeof(newpwd)))
	{
		env_set(&shell->env, "OLDPWD", oldpwd);
		env_set(&shell->env, "PWD", newpwd);
	}
}

static int	minus(t_shell *shell, char *target)
{
	char	cwd[4096];

	target = env_get(shell->env, "OLDPWD");
	if (!target)
	{
		ft_putstr_fd("minishell: cd: OLDPWD not set\n", STDERR_FILENO);
		return (1);
	}
	if (!getcwd(cwd, sizeof(cwd)))
		cwd[0] = '\0';
	if (chdir(target) == -1)
	{
		perror("minishell: cd");
		return (1);
	}
	update_pwd(shell, cwd);
	return (0);
}

int	builtin_cd(t_cmd *cmd, t_shell *shell)
{
	char	*target;
	char	oldpwd[4096];

	if (cmd->args->next)
		target = cmd->args->next->value;
	else
		target = env_get(shell->env, "HOME");
	if (!target)
	{
		ft_putstr_fd("minishell: cd: HOME not set\n", STDERR_FILENO);
		return (1);
	}
	if (ft_strncmp("-", target, 2) == 0)
		return (minus(shell, target));
	if (!getcwd(oldpwd, sizeof(oldpwd)))
		oldpwd[0] = '\0';
	if (chdir(target) == -1)
	{
		perror("minishell: cd");
		return (1);
	}
	update_pwd(shell, oldpwd);
	return (0);
}

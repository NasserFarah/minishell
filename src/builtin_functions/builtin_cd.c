/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_cd.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:45:03 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/21 22:45:07 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	update_pwd(t_shell *shell, char *oldpwd)
{
	char	newpwd[4096];

	if (getcwd(newpwd, 4096))
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
	if (!getcwd(cwd, 4096))
		cwd[0] = '\0';
	if (chdir(target) == -1)
	{
		perror("minishell: cd");
		return (1);
	}
	update_pwd(shell, cwd);
	return (0);
}

static int	lone(char *cwd, const char *target, t_shell *shell)
{
	if (!getcwd(cwd, 4096))
		cwd[0] = '\0';
	if (chdir(target) == -1)
		return (perror("minishell: cd"), 1);
	update_pwd(shell, cwd);
	return (0);
}

int	builtin_cd(t_cmd *cmd, t_shell *shell)
{
	char	*target;
	char	oldpwd[4096];

	if (cmd->args && cmd->args->next)
		target = cmd->args->next->value;
	else
		target = env_get(shell->env, "HOME");
	if (!target)
	{
		ft_putstr_fd("minishell: cd: HOME not set\n", STDERR_FILENO);
		return (1);
	}
	if (cmd->args->next == NULL)
		return (lone(oldpwd, target, shell));
	if (cmd->args->next->next)
		return (ft_putstr_fd("bash: cd: too many arguments\n", 2), 1);
	if (ft_strncmp("-", target, 2) == 0)
		return (minus(shell, target));
	if (!getcwd(oldpwd, sizeof(oldpwd)))
		oldpwd[0] = '\0';
	if (chdir(target) == -1)
		return (perror("minishell: cd"), 1);
	update_pwd(shell, oldpwd);
	return (0);
}

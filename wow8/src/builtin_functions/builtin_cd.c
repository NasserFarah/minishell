/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_cd.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:26:46 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:28:39 by fnasser          ###   ########.fr       */
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

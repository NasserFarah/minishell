/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_cd.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:45:03 by fnasser           #+#    #+#             */
/*   Updated: 2026/09/02 22:10:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	cd_error(const char *target)
{
	ft_putstr_fd("minishell: cd: ", STDERR_FILENO);
	ft_putstr_fd((char *)target, STDERR_FILENO);
	ft_putstr_fd(": ", STDERR_FILENO);
	ft_putstr_fd(strerror(errno), STDERR_FILENO);
	ft_putstr_fd("\n", STDERR_FILENO);
	return (1);
}

static int	cd_step(t_shell *shell, const char *target, char **out)
{
	char	*abs;
	char	*canon;

	abs = cd_absolute(shell, target);
	canon = cd_canonical(abs);
	if (canon && chdir(canon) == 0)
	{
		free(abs);
		*out = canon;
		return (0);
	}
	free(canon);
	if (chdir(target) == -1)
		return (free(abs), cd_error(target));
	*out = cd_resolve_pwd(abs);
	return (0);
}

static int	cd_apply(t_shell *shell, const char *target)
{
	char	*newpwd;
	char	*oldpwd;

	newpwd = NULL;
	if (cd_step(shell, target, &newpwd) != 0)
		return (1);
	oldpwd = shell->cwd;
	shell->cwd = newpwd;
	if (oldpwd)
		env_set(&shell->env, "OLDPWD", oldpwd);
	if (newpwd)
		env_set(&shell->env, "PWD", newpwd);
	free(oldpwd);
	return (0);
}

static int	cd_minus(t_shell *shell)
{
	char	*target;
	int		status;

	target = env_get(shell->env, "OLDPWD");
	if (!target)
		return (ft_putstr_fd("minishell: cd: OLDPWD not set\n", 2), 1);
	target = ft_strduplicate(target);
	if (!target)
		return (1);
	status = cd_apply(shell, target);
	free(target);
	if (status == 0 && shell->cwd)
		ft_putendl_fd(shell->cwd, STDOUT_FILENO);
	return (status);
}

int	builtin_cd(t_cmd *cmd, t_shell *shell)
{
	char	*target;

	if (cmd->args->next && cmd->args->next->next)
		return (ft_putstr_fd("minishell: cd: too many arguments\n", 2), 1);
	if (cmd->args->next)
		target = cmd->args->next->value;
	else
		target = env_get(shell->env, "HOME");
	if (!target)
		return (ft_putstr_fd("minishell: cd: HOME not set\n", 2), 1);
	if (!*target)
		return (0);
	if (ft_strncmp(target, "-", 2) == 0)
		return (cd_minus(shell));
	return (cd_apply(shell, target));
}

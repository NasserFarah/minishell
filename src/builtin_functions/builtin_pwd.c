/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_pwd.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:46:24 by fnasser           #+#    #+#             */
/*   Updated: 2026/09/02 22:10:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

void	getcwd_error(const char *who)
{
	ft_putstr_fd("minishell: ", STDERR_FILENO);
	ft_putstr_fd((char *)who, STDERR_FILENO);
	ft_putstr_fd(": error retrieving current directory:", STDERR_FILENO);
	ft_putstr_fd(" getcwd: cannot access parent directories: ",
		STDERR_FILENO);
	ft_putendl_fd(strerror(errno), STDERR_FILENO);
}

char	*cd_resolve_pwd(char *fallback)
{
	char	cwd[4096];

	if (getcwd(cwd, sizeof(cwd)))
	{
		free(fallback);
		return (ft_strduplicate(cwd));
	}
	getcwd_error("cd");
	return (fallback);
}

int	builtin_pwd(t_cmd *cmd, t_shell *shell)
{
	char	cwd[4096];

	(void)cmd;
	if (shell->cwd)
		return (ft_putendl_fd(shell->cwd, STDOUT_FILENO), 0);
	if (getcwd(cwd, sizeof(cwd)))
		return (ft_putendl_fd(cwd, STDOUT_FILENO), 0);
	getcwd_error("pwd");
	return (1);
}

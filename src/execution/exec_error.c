/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_error.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/29 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/08/29 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

void	free_envp(char **envp)
{
	int	i;

	if (!envp)
		return ;
	i = 0;
	while (envp[i])
		free(envp[i++]);
	free(envp);
}

int	report_exec_error(const char *path)
{
	struct stat	st;

	ft_putstr_fd("minishell: ", STDERR_FILENO);
	ft_putstr_fd((char *)path, STDERR_FILENO);
	if ((errno == EACCES || errno == EISDIR)
		&& stat(path, &st) == 0 && S_ISDIR(st.st_mode))
	{
		ft_putstr_fd(": Is a directory\n", STDERR_FILENO);
		return (126);
	}
	if (errno == ENOENT)
	{
		ft_putstr_fd(": No such file or directory\n", STDERR_FILENO);
		return (127);
	}
	if (errno == EACCES)
	{
		ft_putstr_fd(": Permission denied\n", STDERR_FILENO);
		return (126);
	}
	ft_putstr_fd(": ", STDERR_FILENO);
	ft_putstr_fd(strerror(errno), STDERR_FILENO);
	ft_putstr_fd("\n", STDERR_FILENO);
	return (126);
}

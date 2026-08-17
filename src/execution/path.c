/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   path.c                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static char	*join_path(const char *dir, const char *cmd)
{
	char	*tmp;
	char	*full;

	tmp = ft_strjoin(dir, "/");
	if (!tmp)
		return (NULL);
	full = ft_strjoin(tmp, cmd);
	free(tmp);
	return (full);
}

static void	free_split(char **arr)
{
	int	i;

	i = 0;
	while (arr[i])
	{
		free(arr[i]);
		i++;
	}
	free(arr);
}

static int	try_candidate(char *candidate, int *exit_code)
{
	if (!candidate)
		return (0);
	if (access(candidate, F_OK) != 0)
	{
		free(candidate);
		return (0);
	}
	if (access(candidate, X_OK) == 0)
		return (1);
	*exit_code = 126;
	free(candidate);
	return (0);
}

static char	*search_path(const char *cmd, t_env *env, int *exit_code)
{
	char	*path_val;
	char	**dirs;
	char	*candidate;
	int		i;

	path_val = env_get(env, "PATH");
	if (!path_val)
		return (NULL);
	dirs = ft_split(path_val, ':');
	if (!dirs)
		return (NULL);
	i = 0;
	while (dirs[i])
	{
		candidate = join_path(dirs[i], cmd);
		if (try_candidate(candidate, exit_code))
		{
			free_split(dirs);
			return (candidate);
		}
		i++;
	}
	free_split(dirs);
	return (NULL);
}

char	*resolve_executable(const char *cmd, t_env *env, int *exit_code)
{
	*exit_code = 127;
	if (ft_strchr(cmd, '/'))
	{
		if (access(cmd, F_OK) != 0)
			return (NULL);
		if (access(cmd, X_OK) != 0)
		{
			*exit_code = 126;
			return (NULL);
		}
		return (ft_strdup(cmd));
	}
	return (search_path(cmd, env, exit_code));
}

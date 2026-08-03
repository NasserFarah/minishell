/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   exec_arrays.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:30:01 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:30:03 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

char	**build_argv(t_token *args)
{
	int		n;
	char	**argv;
	t_token	*cur;
	int		i;

	n = 0;
	cur = args;
	while (cur)
	{
		n++;
		cur = cur->next;
	}
	argv = malloc(sizeof(char *) * (n + 1));
	if (!argv)
		return (NULL);
	i = 0;
	while (args)
	{
		argv[i] = args->value;
		i++;
		args = args->next;
	}
	argv[i] = NULL;
	return (argv);
}

static int	count_env(t_env *env)
{
	int	n;

	n = 0;
	while (env)
	{
		n++;
		env = env->next;
	}
	return (n);
}

static char	*env_entry(t_env *env)
{
	char	*eq;
	char	*entry;
	char	*value;

	eq = ft_strjoin(env->key, "=");
	if (env->value)
		value = env->value;
	else
		value = "";
	entry = ft_strjoin(eq, value);
	free(eq);
	return (entry);
}

char	**build_envp(t_env *env)
{
	int		n;
	char	**envp;
	int		i;
	t_env	*cur;

	n = count_env(env);
	envp = malloc(sizeof(char *) * (n + 1));
	if (!envp)
		return (NULL);
	i = 0;
	cur = env;
	while (cur)
	{
		envp[i] = env_entry(cur);
		i++;
		cur = cur->next;
	}
	envp[i] = NULL;
	return (envp);
}

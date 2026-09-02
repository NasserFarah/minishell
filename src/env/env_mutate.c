/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   env_mutate.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/31 23:08:30 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:08:34 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

void	env_append_new(t_env **env, const char *key, const char *value)
{
	t_env	*node;
	t_env	*cur;

	node = malloc(sizeof(t_env));
	if (!node)
		return ;
	node->key = ft_strduplicate(key);
	node->value = ft_strduplicate(value);
	node->next = NULL;
	if (!*env)
	{
		*env = node;
		return ;
	}
	cur = *env;
	while (cur->next)
		cur = cur->next;
	cur->next = node;
}

void	env_set(t_env **env, const char *key, const char *value)
{
	t_env	*cur;

	cur = *env;
	while (cur)
	{
		if (cur->key && ft_strncmp(cur->key, key, ft_strlen(key) + 1) == 0)
		{
			free(cur->value);
			cur->value = ft_strduplicate(value);
			return ;
		}
		cur = cur->next;
	}
	env_append_new(env, key, value);
}

void	env_unset(t_env **env, const char *key)
{
	t_env	*cur;
	t_env	*prev;

	cur = *env;
	prev = NULL;
	while (cur)
	{
		if (cur->key && ft_strncmp(cur->key, key, ft_strlen(key) + 1) == 0)
		{
			if (prev)
				prev->next = cur->next;
			else
				*env = cur->next;
			free(cur->key);
			free(cur->value);
			free(cur);
			return ;
		}
		prev = cur;
		cur = cur->next;
	}
}

void	shlvl(t_shell *shell)
{
	char	*shlvl;
	int		lvl;

	shlvl = env_get(shell->env, "SHLVL");
	if (!shlvl)
		lvl = 0;
	else
	{
		lvl = ft_atoi(shlvl);
		if (lvl < 0)
			lvl = 0;
	}
	lvl++;
	shlvl = ft_itoa(lvl);
	if (shlvl)
	{
		env_set(&shell->env, "SHLVL", shlvl);
		free(shlvl);
	}
}

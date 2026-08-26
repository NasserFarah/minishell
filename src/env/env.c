/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   env.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 22:43:27 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/27 22:43:27 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static t_env	*new_env_node(char *key, char *value)
{
	t_env	*node;

	node = malloc(sizeof(t_env));
	if (!node)
		return (NULL);
	node->key = key;
	node->value = value;
	node->next = NULL;
	return (node);
}

static void	env_add_back(t_env **head, t_env *new)
{
	t_env	*last;

	if (!*head)
	{
		*head = new;
		return ;
	}
	last = *head;
	while (last->next)
		last = last->next;
	last->next = new;
}

t_env	*env_init(char **envp)
{
	t_env	*head;
	t_env	*node;
	char	*eq;
	int		i;

	head = NULL;
	i = 0;
	while (envp[i])
	{
		eq = ft_strchr(envp[i], '=');
		if (eq)
			node = new_env_node(ft_substr(envp[i], 0, eq - envp[i]),
					ft_strduplicate(eq + 1));
		else
			node = new_env_node(ft_strduplicate(envp[i]), NULL);
		env_add_back(&head, node);
		i++;
	}
	return (head);
}

void	free_env(t_env *env)
{
	t_env	*next;

	while (env)
	{
		next = env->next;
		free(env->key);
		free(env->value);
		free(env);
		env = next;
	}
}

char	*env_get(t_env *env, const char *key)
{
	size_t	len;

	len = ft_strlen(key);
	while (env)
	{
		if (env->key && ft_strncmp(env->key, key, len + 1) == 0)
			return (env->value);
		env = env->next;
	}
	return (NULL);
}

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tilde.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/26 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/26 00:00:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static char	*tilde_prefix(const char *word)
{
	int	i;

	i = 0;
	while (word[i] != '\0' && word[i] != '/')
		i++;
	return (ft_substr(word, 0, i));
}

static char	*expand_tilde_prefix(char *prefix, t_shell *shell)
{
	char	*value;

	value = NULL;
	if (ft_strncmp(prefix, "~", 2) == 0)
		value = env_get(shell->env, "HOME");
	else if (ft_strncmp(prefix, "~+", 3) == 0)
		value = env_get(shell->env, "PWD");
	else if (ft_strncmp(prefix, "~-", 3) == 0)
		value = env_get(shell->env, "OLDPWD");
	if (value)
		return (ft_strduplicate(value));
	return (NULL);
}

char	*tilde_expansion(char *word, t_shell *shell)
{
	char	*result;
	char	*prefix;
	char	*value;

	if (word[0] != '~')
		return (word);
	prefix = tilde_prefix(word);
	value = expand_tilde_prefix(prefix, shell);
	if (!value)
	{
		result = ft_strdup("/home");
		free(word);
	}
	else
	{
		result = ft_strjoin(value, word + ft_strlen(prefix));
		free(value);
		free(word);
	}
	free(prefix);
	return (result);
}

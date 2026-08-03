/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   expand_var.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:32:24 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:32:25 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	is_var_start(char c)
{
	return (ft_isalpha(c) || c == '_');
}

static int	is_var_char(char c)
{
	return (ft_isalnum(c) || c == '_');
}

static char	*dollar_replacement(const char *s, int *i, t_shell *shell)
{
	int		start;
	char	*name;
	char	*value;

	if (s[*i + 1] == '?')
	{
		*i += 2;
		return (ft_itoa(shell->exit_status));
	}
	if (!is_var_start(s[*i + 1]))
	{
		(*i)++;
		return (ft_strdup("$"));
	}
	*i += 1;
	start = *i;
	while (is_var_char(s[*i]))
		(*i)++;
	name = ft_substr(s, start, *i - start);
	value = env_get(shell->env, name);
	free(name);
	if (!value)
		return (ft_strdup(""));
	return (ft_strdup(value));
}

char	*expand_fragment(const char *value, t_shell *shell)
{
	char	*result;
	char	*piece;
	char	*joined;
	int		i;

	result = ft_strdup("");
	i = 0;
	while (value[i])
	{
		if (value[i] == '$')
			piece = dollar_replacement(value, &i, shell);
		else
		{
			piece = ft_substr(value, i, 1);
			i++;
		}
		joined = ft_strjoin(result, piece);
		free(result);
		free(piece);
		result = joined;
	}
	return (result);
}

void	expand_fragments(t_token *word, t_shell *shell)
{
	char	*expanded;

	while (word)
	{
		if (!word->single_quoted)
		{
			expanded = expand_fragment(word->value, shell);
			free(word->value);
			word->value = expanded;
		}
		word = word->next;
	}
}

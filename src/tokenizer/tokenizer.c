/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tokenizer.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/31 23:11:24 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:11:27 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

int	is_operator_char(char c)
{
	return (c == '|' || c == '<' || c == '>');
}

static void	skip_spaces(const char *line, int *i)
{
	while (line[*i] == ' ' || line[*i] == '\t')
		(*i)++;
}

static t_token	*make_operator_token(const char *line, int *i)
{
	if (line[*i] == '|')
	{
		(*i)++;
		return (new_token(TOKEN_PIPE, NULL, 0, 0));
	}
	if (line[*i] == '<')
	{
		if (line[*i + 1] == '<')
		{
			*i += 2;
			return (new_token(TOKEN_HEREDOC, NULL, 0, 0));
		}
		(*i)++;
		return (new_token(TOKEN_REDIR_IN, NULL, 0, 0));
	}
	if (line[*i + 1] == '>')
	{
		*i += 2;
		return (new_token(TOKEN_REDIR_APPEND, NULL, 0, 0));
	}
	(*i)++;
	return (new_token(TOKEN_REDIR_OUT, NULL, 0, 0));
}

static int	next_token(const char *line, int *i, t_token **head, int *error)
{
	t_token	*part;

	if (is_operator_char(line[*i]))
		part = make_operator_token(line, i);
	else
		part = make_word_token(line, i, error);
	if (!part)
		return (1);
	add_token_back(head, part);
	return (0);
}

t_token	*tokenize(const char *line, int *error)
{
	t_token	*head;
	int		i;

	head = NULL;
	i = 0;
	while (line[i])
	{
		skip_spaces(line, &i);
		if (!line[i])
			break ;
		if (next_token(line, &i, &head, error))
		{
			free_tokens(head);
			return (NULL);
		}
	}
	return (head);
}

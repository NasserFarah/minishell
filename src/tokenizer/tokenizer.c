/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tokenizer.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
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

static int	next_token(const char *line, int *i, t_token **head)
{
	t_token	*part;
	int		error;

	error = 0;
	if (is_operator_char(line[*i]))
		part = make_operator_token(line, i);
	else
		part = make_word_token(line, i, &error);
	if (!part)
		return (1);
	add_token_back(head, part);
	return (0);
}

t_token	*tokenize(const char *line)
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
		if (next_token(line, &i, &head))
		{
			free_tokens(head);
			return (NULL);
		}
	}
	return (head);
}

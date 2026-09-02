/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tokenizer_word.c                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/31 23:12:05 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:12:07 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	segment_continues(const char *line, int i)
{
	if (!line[i])
		return (0);
	if (line[i] == ' ' || line[i] == '\t')
		return (0);
	if (is_operator_char(line[i]))
		return (0);
	return (1);
}

static t_token	*parse_quoted_segment(const char *line, int *i, int *error)
{
	char	quote;
	int		start;
	t_token	*token;

	quote = line[*i];
	(*i)++;
	start = *i;
	while (line[*i] && line[*i] != quote)
		(*i)++;
	if (!line[*i])
	{
		write(STDERR_FILENO, "minishell: unclosed quote\n", 26);
		*error = 1;
		return (NULL);
	}
	token = new_token(TOKEN_WORD, ft_substr(line, start, *i - start), 0, 0);
	(*i)++;
	if (token && quote == '\'')
		token->single_quoted = 1;
	else if (token)
		token->double_quoted = 1;
	return (token);
}

static t_token	*parse_bare_segment(char *line, int *i)
{
	int	start;
	int	open;
	int	close;

	start = *i;
	open = 0;
	close = 0;
	while (segment_continues(line, *i) && line[*i] != '\''
		&& line[*i] != '"')
	{
		if (line[*i] == '(')
			open = 1;
		if (line[*i] == ')')
			close = 1;
		(*i)++;
	}
	line = ft_substr(line, start, *i - start);
	return (new_token(TOKEN_WORD, line, open, close));
}

t_token	*make_word_token(const char *line, int *i, int *error)
{
	t_token	*head;
	t_token	*seg;

	head = NULL;
	while (segment_continues(line, *i))
	{
		if (line[*i] == '\'' || line[*i] == '"')
			seg = parse_quoted_segment(line, i, error);
		else
			seg = parse_bare_segment((char *)line, i);
		if (!seg)
		{
			free_tokens(head);
			return (NULL);
		}
		if (segment_continues(line, *i))
			seg->join_next = 1;
		add_token_back(&head, seg);
	}
	return (head);
}

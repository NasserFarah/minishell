/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   lex.c                                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/24 15:04:35 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/24 15:04:37 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

int	op_beginning(char c)
{
	if (c == '|' || c == '<' || c == '>')
		return (1);
	return (0);
}

// after the operator is detected, this function extracts the op
// and flags it with its type.
static t_tkn	*extract_op(char *inp, size_t *i)
{
	char	c;

	c = inp[*i];
	(*i)++;
	if (c == '|')
		return ((create_tkn(TKN_PIPE, ft_strdup("|"))));
	if (c == '>')
	{
		if (inp[*i] == '>')
		{
			(*i)++;
			return (create_tkn(TKN_APPEND, ft_strdup(">>")));
		}
		return (create_tkn(TKN_REDIR_OUT, ft_strdup(">")));
	}
	if (c == '<')
	{
		if (inp[*i] == '<')
		{
			(*i)++;
			return (create_tkn(TKN_HEREDOC, ft_strdup("<<")));
		}
	}
	return (create_tkn(TKN_REDIR_IN, ft_strdup("<")));
}

// detects unclosed quotes
static int	unclosed_quotes(t_lexer t)
{
	if (t.error)
	{
		ft_putstr_fd("minishell: syntax error: unclosed quote\n", 2);
		free_tknz(t.head);
		return (1);
	}
	return (0);
}

// initializes the lexer's struct
static void	t_init(t_lexer *t)
{
	t->head = NULL;
	t->tail = NULL;
	t->i = 0;
	t->error = 0;
}

// t_lex fn is the lexer function,
// it returns a pointer to the head of a list of tokens,
// each flagged by its own token type
// skips the whitespaces
// tracks the beginning of an operator '|', '<', or '>'
// reads a command as a word
t_tkn	*t_lex(char *inp)
{
	t_lexer	t;

	t_init(&t);
	while (inp[t.i] != 0)
	{
		while (inp[t.i] && is_whitespace(inp[t.i]))
			t.i++;
		if (inp[t.i] == 0)
			break ;
		if ((op_beginning(inp[t.i])))
		{
			t.curr = extract_op(inp, &t.i);
			add_tkn(&t.head, &t.tail, t.curr);
		}
		else
		{
			t.curr = read_word(inp, &t.i, &t.error);
			if (unclosed_quotes(t))
				return (NULL);
			add_tkn(&t.head, &t.tail, t.curr);
		}
	}
	return (t.head);
}

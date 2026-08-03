/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tokenizer.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 18:19:43 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/27 18:50:54 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

static char	*word_append(char *word, size_t *len, size_t *space, char c)
{
	char	*bigger;

	if (*len + 1 >= *space)
	{
		*space *= 2;
		bigger = malloc(*space);
		if (!bigger)
		{
			perror("Malloc");
			exit(1);
		}
		ft_memcpy(bigger, word, *len);
		free(word);
		word = bigger;
	}
	word[(*len)++] = c;
	return (word);
}

static int	read_single_quote(t_red *red)
{
	(*red->i)++;
	while (red->inp[*red->i] && red->inp[*red->i] != '\'')
	{
		red->word = word_append(red->word, &red->len, &red->space,
				red->inp[*red->i]);
		(*red->i)++;
	}
	if (!red->inp[*red->i])
		return (-1);
	(*red->i)++;
	return (0);
}

static int	read_double_quote(t_red *red)
{
	(*red->i)++;
	while (red->inp[*red->i] && red->inp[*red->i] != '"')
	{
		red->word = word_append(red->word, &red->len, &red->space,
				red->inp[*red->i]);
		(*red->i)++;
	}
	if (!red->inp[*red->i])
		return (-1);
	(*red->i)++;
	return (0);
}

t_tkn	*read_word(char *inp, size_t *i, int *error)
{
	t_red	red;
	int		count;

	red.space = 64;
	red.len = 0;
	red.word = safe_malloc(red.space);
	count = 0;
	if (!red.word)
		return (perror("Malloc"), exit(1), NULL);
	red.inp = inp;
	red.i = i;
	while (inp[*i] && !is_whitespace(inp[*i]) && !op_beginning(inp[*i]))
	{
		if (inp[*i] == '\'')
			count = read_single_quote(&red);
		else if (inp[*i] == '"')
			count = read_double_quote(&red);
		else
			red.word = word_append(red.word, &red.len, &red.space, inp[(*i)++]);
		if (count == -1)
			return ((free(red.word)), (*error = 1), NULL);
	}
	red.word = word_append(red.word, &red.len, &red.space, 0);
	return ((create_tkn(TKN_WORD, red.word)));
}

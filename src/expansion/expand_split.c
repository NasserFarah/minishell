/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   expand_split.c                                   :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	finalize_word(t_split *sp)
{
	t_token	*tok;

	if (sp->touched)
	{
		tok = new_token(TOKEN_WORD, sp->acc, 0, 0);
		add_token_back(&sp->out, tok);
	}
	else
		free(sp->acc);
	sp->acc = ft_strdup("");
	sp->touched = 0;
}

static void	glue(char *text, t_split *sp)
{
	char	*joined;

	joined = ft_strjoin(sp->acc, text);
	free(sp->acc);
	sp->acc = joined;
	sp->touched = 1;
}

static void	split_bare(char *text, t_split *sp)
{
	int		i;
	int		start;
	char	*chunk;

	i = 0;
	if (text[0] && (text[0] == ' ' || text[0] == '\t'))
		finalize_word(sp);
	while (text[i])
	{
		while (text[i] == ' ' || text[i] == '\t')
			i++;
		if (!text[i])
			break ;
		start = i;
		while (text[i] && text[i] != ' ' && text[i] != '\t')
			i++;
		chunk = ft_substr(text, start, i - start);
		glue(chunk, sp);
		free(chunk);
		if (text[i])
			finalize_word(sp);
	}
}

t_token	*split_word(t_token *word)
{
	t_split	sp;

	sp.acc = ft_strdup("");
	sp.touched = 0;
	sp.out = NULL;
	while (word)
	{
		if (word->single_quoted || word->double_quoted)
			glue(word->value, &sp);
		else
			split_bare(word->value, &sp);
		word = word->next;
	}
	finalize_word(&sp);
	free(sp.acc);
	return (sp.out);
}

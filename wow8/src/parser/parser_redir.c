/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parser_redir.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:33:37 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:33:39 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static t_redir_type	redir_type(t_token_type type)
{
	if (type == TOKEN_REDIR_IN)
		return (REDIR_IN);
	if (type == TOKEN_REDIR_OUT)
		return (REDIR_OUT);
	if (type == TOKEN_REDIR_APPEND)
		return (REDIR_APPEND);
	return (REDIR_HEREDOC);
}

static void	append_redir(t_redir **redirs, t_redir *new)
{
	t_redir	*last;

	if (!*redirs)
	{
		*redirs = new;
		return ;
	}
	last = *redirs;
	while (last->next)
		last = last->next;
	last->next = new;
}

int	consume_redir(t_token **tokens, t_redir **redirs)
{
	t_redir	*redir;
	t_token	*op;

	op = *tokens;
	redir = malloc(sizeof(t_redir));
	if (!redir)
		return (0);
	redir->type = redir_type(op->type);
	*tokens = op->next;
	free(op);
	redir->target = take_word(tokens);
	redir->heredoc_expand = 1;
	redir->heredoc_fd = -1;
	redir->next = NULL;
	append_redir(redirs, redir);
	return (1);
}

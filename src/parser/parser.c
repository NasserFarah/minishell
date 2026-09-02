/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parser.c                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/31 23:10:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:10:04 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	skip_pipe(t_token **tokens)
{
	t_token	*pipe;

	pipe = *tokens;
	*tokens = pipe->next;
	free(pipe);
}

static int	parse_token(t_token **tokens, t_cmd *cmd)
{
	if ((*tokens)->type == TOKEN_WORD)
	{
		add_token_back(&cmd->args, take_word(tokens));
		return (1);
	}
	return (consume_redir(tokens, &cmd->redirs));
}

static t_cmd	*parse_command(t_token **tokens)
{
	t_cmd	*cmd;
	int		ok;

	cmd = new_cmd();
	if (!cmd)
	{
		free_tokens(*tokens);
		*tokens = NULL;
		return (NULL);
	}
	ok = 1;
	while (ok && *tokens && (*tokens)->type != TOKEN_PIPE)
		ok = parse_token(tokens, cmd);
	if (!ok)
	{
		free_tokens(*tokens);
		*tokens = NULL;
		free_cmd(cmd);
		return (NULL);
	}
	return (cmd);
}

t_cmd	*parse(t_token **tokens)
{
	t_cmd	*head;
	t_cmd	*cur;

	head = parse_command(tokens);
	if (!head)
		return (NULL);
	cur = head;
	while (*tokens)
	{
		skip_pipe(tokens);
		cur->next = parse_command(tokens);
		if (!cur->next)
		{
			free_cmd(head);
			return (NULL);
		}
		cur = cur->next;
	}
	return (head);
}

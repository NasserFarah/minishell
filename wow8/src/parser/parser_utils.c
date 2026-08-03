/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   parser_utils.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 23:33:44 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/30 23:33:46 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

t_cmd	*new_cmd(void)
{
	t_cmd	*cmd;

	cmd = malloc(sizeof(t_cmd));
	if (!cmd)
		return (NULL);
	cmd->args = NULL;
	cmd->redirs = NULL;
	cmd->next = NULL;
	return (cmd);
}

t_token	*take_word(t_token **tokens)
{
	t_token	*head;
	t_token	*cur;

	head = *tokens;
	cur = head;
	while (cur->join_next)
		cur = cur->next;
	*tokens = cur->next;
	cur->next = NULL;
	return (head);
}

static void	free_redirs(t_redir *redirs)
{
	t_redir	*next;

	while (redirs)
	{
		next = redirs->next;
		free_tokens(redirs->target);
		free(redirs);
		redirs = next;
	}
}

void	free_cmd(t_cmd *cmd)
{
	t_cmd	*next;

	while (cmd)
	{
		next = cmd->next;
		free_tokens(cmd->args);
		free_redirs(cmd->redirs);
		free(cmd);
		cmd = next;
	}
}

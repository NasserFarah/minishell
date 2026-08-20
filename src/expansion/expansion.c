/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   expansion.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass          #+#    #+#             */
/*   Updated: 2026/08/21 00:14:01 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	is_assignment_word(t_token *word)
{
	int	x;
	int	y;

	x = ft_strchr(word->value, '=') != NULL;
	y = is_valid_name(word->value) == 1;
	if (x == 1 && y == 1)
		return (1);
	return (0);
}

static void	expand_cmd_args(t_cmd *cmd, t_shell *shell)
{
	t_token	*old;
	t_token	*word;
	t_token	*new_args;
	int		is_export;

	old = cmd->args;
	new_args = NULL;
	is_export = 0;
	if (old && ft_strncmp(old->value, "export", 7) == 0)
		is_export = 1;
	while (old)
	{
		word = take_word(&old);
		expand_fragments(word, shell);
		if (is_export && new_args && is_assignment_word(word))
			add_token_back(&new_args, new_token(TOKEN_WORD, join_word(word)));
		else
			add_token_back(&new_args, split_word(word));
		free_tokens(word);
	}
	cmd->args = new_args;
}

void	expand(t_shell *shell)
{
	t_cmd	*cmd;

	cmd = shell->pipeline;
	while (cmd)
	{
		expand_cmd_args(cmd, shell);
		expand_cmd_redirs(cmd, shell);
		cmd = cmd->next;
	}
}

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   expand_redirs.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

char	*join_word(t_token *word)
{
	char	*acc;
	char	*joined;

	acc = ft_strduplicate("");
	while (word)
	{
		joined = ft_strjoin(acc, word->value);
		free(acc);
		acc = joined;
		word = word->next;
	}
	return (acc);
}

static int	any_quoted(t_token *word)
{
	while (word)
	{
		if (word->single_quoted || word->double_quoted)
			return (1);
		word = word->next;
	}
	return (0);
}

void	expand_cmd_redirs(t_cmd *cmd, t_shell *shell)
{
	t_redir	*redir;
	char	*joined;

	redir = cmd->redirs;
	while (redir)
	{
		if (redir->type == REDIR_HEREDOC)
			redir->heredoc_expand = !any_quoted(redir->target);
		expand_fragments(redir->target, shell);
		joined = join_word(redir->target);
		free_tokens(redir->target);
		redir->target = new_token(TOKEN_WORD, joined, 0, 0);
		redir = redir->next;
	}
}

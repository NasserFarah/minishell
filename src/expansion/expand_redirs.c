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

static void	expand_heredoc_target(t_redir *redir)
{
	char	*joined;

	redir->heredoc_expand = !any_quoted(redir->target);
	joined = join_word(redir->target);
	free_tokens(redir->target);
	redir->target = new_token(TOKEN_WORD, joined, 0, 0);
}

static void	expand_output_target(t_redir *redir, t_shell *shell)
{
	t_token	*fields;
	char	*original;

	if (redir->target && !redir->target->single_quoted
		&& !redir->target->double_quoted)
		redir->target->value = tilde_expansion(redir->target->value, shell);
	original = join_word(redir->target);
	expand_fragments(redir->target, shell);
	fields = split_word(redir->target);
	free_tokens(redir->target);
	if (fields && !fields->next)
	{
		free(original);
		redir->target = fields;
	}
	else
	{
		redir->ambiguous = 1;
		redir->target = new_token(TOKEN_WORD, original, 0, 0);
		free_tokens(fields);
	}
}

void	expand_cmd_redirs(t_cmd *cmd, t_shell *shell)
{
	t_redir	*redir;

	redir = cmd->redirs;
	while (redir)
	{
		if (redir->type == REDIR_HEREDOC)
			expand_heredoc_target(redir);
		else
			expand_output_target(redir, shell);
		redir = redir->next;
	}
}

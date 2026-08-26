/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tokenizer_validate.c                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	is_redir(t_token_type type)
{
	return (type == TOKEN_REDIR_IN || type == TOKEN_REDIR_OUT
		|| type == TOKEN_REDIR_APPEND || type == TOKEN_HEREDOC);
}

static int	validate_pipes(t_token *tokens)
{
	t_token	*prev;

	prev = NULL;
	while (tokens)
	{
		if (tokens->type != TOKEN_PIPE)
		{
			prev = tokens;
			tokens = tokens->next;
			continue ;
		}
		if (!prev)
			return (print_syntax_error(tokens), 0);
		if (!tokens->next)
			return (print_syntax_error(NULL), 0);
		if (tokens->next->type == TOKEN_PIPE)
			return (print_syntax_error(tokens->next), 0);
		prev = tokens;
		tokens = tokens->next;
	}
	return (1);
}

static int	validate_redirs(t_token *tokens)
{
	while (tokens)
	{
		if (is_redir(tokens->type) && !tokens->next)
			return (print_syntax_error(NULL), 0);
		if (is_redir(tokens->type) && tokens->next->type != TOKEN_WORD)
			return (print_syntax_error(tokens->next), 0);
		tokens = tokens->next;
	}
	return (1);
}

static int	brace_syntax(t_token *tokens)
{
	while (tokens)
	{
		if (tokens->open == 1 || tokens->close == 1)
		{
			ft_putstr_fd("minishell: syntax error near unexpected token `",
				STDERR_FILENO);
			if (tokens->open == 1)
				ft_putstr_fd("(", STDERR_FILENO);
			else
				ft_putstr_fd(")", STDERR_FILENO);
			ft_putstr_fd("'\n", STDERR_FILENO);
			return (0);
		}
		tokens = tokens->next;
	}
	return (1);
}

int	validate_tokens(t_token *tokens)
{
	if (!validate_pipes(tokens))
		return (0);
	if (!validate_redirs(tokens))
		return (0);
	if (!brace_syntax(tokens))
		return (0);
	return (1);
}

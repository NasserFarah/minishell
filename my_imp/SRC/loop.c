/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   loop.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/24 15:04:09 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/26 19:21:17 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

// returns the token type for each token
// for printing
static const char	*get_tkn_type(t_tkn_type type)
{
	if (type == TKN_WORD)
		return ("WORD");
	if (type == TKN_PIPE)
		return ("PIPE");
	if (type == TKN_REDIR_IN)
		return ("REDIR_IN");
	if (type == TKN_REDIR_OUT)
		return ("REDIR_OUT");
	if (type == TKN_HEREDOC)
		return ("HEREDOC");
	if (type == TKN_APPEND)
		return ("APPEND");
	return ("UNKNOWN");
}

// prints for debugging
static void	print_tkns(t_tkn *tkns)
{
	int	i;

	i = 0;
	while (tkns)
	{
		printf("[%d] %-10s -> \"%s\"\n",
			i,
			get_tkn_type(tkns->type),
			tkns->rex);
		tkns = tkns->nxt;
		i++;
	}
}

// readline reads a line from terminal and returns it
// using its argument as a prompt
// add_history places inp at the end of the history list.
// t_lex fn is the lexer function,
// it returns a list of tokens, each flagged by its own token type
// 
void	shloop(char **env)
{
	char		*inp;
	t_tkn		*tkns;
	t_tkn		*curr;
	t_parser	*ast;
	//char	*init_dir;
	(void)env;
	(void)curr;
	inp = NULL;
	while (23)
	{
		inp = readline("minihell$ ");
		if (inp == NULL)
		{
			break ;
		}
		if (*inp)
			add_history(inp);
		tkns = t_lex(inp);
		parse(tkns, &ast);
		// print_tkns(tkns);
		free_tknz(tkns);
		free(inp);
	}
}

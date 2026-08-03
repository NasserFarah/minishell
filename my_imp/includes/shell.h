/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell.h                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/21 00:03:49 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/26 19:20:12 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef SHELL_H
# define SHELL_H

# include "header.h"

# define BUFFER 1024

// struct for read_word fn variables
typedef struct s_red
{
	char	*inp;
	size_t	*i;
	char	*word;
	size_t	len;
	size_t	space;
}		t_red;

//tkn types will be produced in the lexing phase, 
//to mark each token with its type
typedef enum e_tkn_type
{
	TKN_WORD,
	TKN_PIPE,
	TKN_REDIR_IN,
	TKN_REDIR_OUT,
	TKN_HEREDOC,
	TKN_APPEND,
}	t_tkn_type;

// the linked list for the lexer
typedef struct s_tkn
{
	t_tkn_type		type;
	char			*rex;
	struct s_tkn	*nxt;
}	t_tkn;

// used for the t_lex function
typedef struct s_lexer
{
	t_tkn	*head;
	t_tkn	*tail;
	t_tkn	*curr;
	size_t	i;
	int		error;
}	t_lexer;

typedef struct s_redir
{
	t_tkn_type		type;
	char			*file;
	struct s_redir	*next;
}	t_redir;

typedef struct s_parser
{
	char			**av;
	t_redir			*redirs;
	struct s_parser	*left;
	struct s_parser	*right;
}	t_parser;

// libft utils
char	*ft_strdup(const char *s);
void	ft_memcpy(void *dst, const void *src, size_t n);
void	ft_putstr_fd(const char *s, int fd);
int		is_whitespace(char c);
void	*safe_malloc(int size);

// tokenizer
t_tkn	*read_word(char *inp, size_t *i, int *error);

// tkn_actions
void	add_tkn(t_tkn **head, t_tkn **tail, t_tkn *t);
t_tkn	*create_tkn(t_tkn_type type, char *x);

// lex
int		op_beginning(char c);
t_tkn	*t_lex(char *inp);

// parse
void	parse(t_tkn *t, t_parser *ast);

// shell loop fn
void	shloop(char **env);

// free
void	free_tknz(t_tkn *tk);

#endif

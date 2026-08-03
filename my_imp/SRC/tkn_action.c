/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tkn_action.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/26 20:33:46 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/26 20:33:48 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

// creates a token
t_tkn	*create_tkn(t_tkn_type type, char *x)
{
	t_tkn	*t;

	t = malloc(sizeof(t_tkn));
	if (!t)
	{
		perror("Malloc");
		exit(1);
	}
	t->type = type;
	t->rex = x;
	t->nxt = NULL;
	return (t);
}

// adds the token in the linked list
void	add_tkn(t_tkn **head, t_tkn **tail, t_tkn *t)
{
	if (!*head)
	{
		*head = t;
		*tail = t;
	}
	else
	{
		(*tail)->nxt = t;
		*tail = t;
	}
}

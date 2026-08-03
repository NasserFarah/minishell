/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   free_utils.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/24 15:04:19 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/24 15:04:21 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

// frees the tokens list
void	free_tknz(t_tkn *head)
{
	t_tkn	*tmp;

	while (head)
	{
		tmp = head->nxt;
		free(head->rex);
		free(head);
		head = tmp;
	}
}

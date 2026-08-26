/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   tilde_utils.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/26 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/26 00:00:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static int	assign_prefix_len(const char *value)
{
	int	i;

	if (!(ft_isalpha(value[0]) || value[0] == '_'))
		return (0);
	i = 1;
	while (value[i] && (ft_isalnum(value[i]) || value[i] == '_'))
		i++;
	if (value[i] == '=')
		return (i + 1);
	return (0);
}

char	*tilde_expand_assign(char *value, t_shell *shell)
{
	int		plen;
	char	*head;
	char	*tail;
	char	*result;

	plen = assign_prefix_len(value);
	if (plen == 0 || value[plen] != '~')
		return (value);
	head = ft_substr(value, 0, plen);
	tail = tilde_expansion(ft_strduplicate(value + plen), shell);
	result = ft_strjoin(head, tail);
	free(head);
	free(tail);
	free(value);
	return (result);
}

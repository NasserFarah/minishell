/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_env.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:45:33 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/21 22:45:35 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	prnt_env(t_env *cur)
{
	ft_putstr_fd(cur->key, STDOUT_FILENO);
	ft_putchar_fd('=', STDOUT_FILENO);
	ft_putendl_fd(cur->value, STDOUT_FILENO);
}

int	builtin_env(t_cmd *cmd, t_shell *shell)
{
	t_env	*cur;

	(void)cmd;
	cur = shell->env;
	while (cur)
	{
		if (cur->key && cur->value)
			prnt_env(cur);
		cur = cur->next;
	}
	return (0);
}

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
	char	*path_val;

	(void)cmd;
	path_val = env_get(shell->env, "PATH");
	if (!path_val || !*path_val)
	{
		ft_putstr_fd("minishell: env: No such file or directory\n",
			STDERR_FILENO);
		return (127);
	}
	cur = shell->env;
	while (cur)
	{
		if (cur->key && cur->value)
			prnt_env(cur);
		cur = cur->next;
	}
	return (0);
}

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

int	builtin_env(t_cmd *cmd, t_shell *shell)
{
	t_env	*cur;
	int		flag;

	(void)cmd;
	flag = 0;
	cur = shell->env;
	while (cur)
	{
		if ((ft_strncmp(cur->key, "PATH", 5) == 0) && cur->value != NULL)
			flag = 1;
		cur = cur->next;
	}
	if (flag == 0)
		write(2, "bash: env: No such file or directory\n", 37);
	cur = shell->env;
	while (cur && flag)
	{
		if (cur->key && cur->value)
		{
			ft_putstr_fd(cur->key, STDOUT_FILENO);
			ft_putchar_fd('=', STDOUT_FILENO);
			ft_putendl_fd(cur->value, STDOUT_FILENO);
		}
		cur = cur->next;
	}
	return (0);
}

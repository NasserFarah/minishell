/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_unset.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/21 22:46:47 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/21 22:46:49 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

int	builtin_unset(t_cmd *cmd, t_shell *shell)
{
	t_token	*arg;
	int		status;

	arg = cmd->args->next;
	status = 0;
	while (arg)
	{
		env_unset(&shell->env, arg->value);
		arg = arg->next;
	}
	return (status);
}

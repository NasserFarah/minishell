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
		// if (!is_valid_name(arg->value))
		// {
		// 	ft_putstr_fd("minishell: unset: `", STDERR_FILENO);
		// 	ft_putstr_fd(arg->value, STDERR_FILENO);
		// 	ft_putstr_fd("': not a valid identifier\n", STDERR_FILENO);
		// 	status = 1;
		// }
		// else
		env_unset(&shell->env, arg->value);
		arg = arg->next;
	}
	return (status);
}

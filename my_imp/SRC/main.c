/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/21 00:03:19 by fnasser           #+#    #+#             */
/*   Updated: 2026/07/26 19:20:06 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/shell.h"

// main calling shell loop

int	main(int ac, char **av, char **env)
{
	(void)ac;
	(void)av;
	shloop(env);
	return (0);
}

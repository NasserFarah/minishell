/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   expand_var_utils.c                                 :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/28 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/31 23:09:41 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static char	*get_pid_str(void)
{
	int		fd;
	char	buf[32];
	int		n;
	int		i;

	fd = open("/proc/self/stat", O_RDONLY);
	if (fd == -1)
		return (ft_strduplicate(""));
	n = read(fd, buf, sizeof(buf) - 1);
	close(fd);
	if (n <= 0)
		return (ft_strduplicate(""));
	buf[n] = '\0';
	i = 0;
	while (buf[i] && buf[i] != ' ')
		i++;
	return (ft_substr(buf, 0, i));
}

char	*special_var(char c, t_shell *shell)
{
	if (c == '?')
		return (ft_itoa(shell->exit_status));
	return (get_pid_str());
}

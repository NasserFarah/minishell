/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   heredoc_utils.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/26 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/28 03:53:56 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

int	is_delim(const char *line, const char *delim)
{
	return (ft_strlen(line) == ft_strlen(delim)
		&& ft_strncmp(line, delim, ft_strlen(delim) + 1) == 0);
}

void	warn_eof(const char *delim)
{
	ft_putstr_fd("minishell: warning: here-document delimited", STDERR_FILENO);
	ft_putstr_fd(" by end-of-file (wanted `", STDERR_FILENO);
	ft_putstr_fd((char *)delim, STDERR_FILENO);
	ft_putstr_fd("')\n", STDERR_FILENO);
}

char	*heredoc_line(void)
{
	char	*line;
	size_t	len;

	if (isatty(STDIN_FILENO))
		write(STDOUT_FILENO, "> ", 2);
	line = get_next_line(STDIN_FILENO);
	if (!line)
		return (NULL);
	len = ft_strlen(line);
	if (len > 0 && line[len - 1] == '\n')
		line[len - 1] = '\0';
	return (line);
}

int	open_heredoc_file(char *path, size_t size)
{
	int		i;
	int		fd;
	char	*num;

	i = 0;
	while (i < 4096)
	{
		num = ft_itoa(i);
		if (!num)
			return (-1);
		ft_strlcpy(path, "/tmp/.minishell_heredoc_", size);
		ft_strlcat(path, num, size);
		free(num);
		fd = open(path, O_WRONLY | O_CREAT | O_EXCL, 0600);
		if (fd != -1)
			return (fd);
		i++;
	}
	return (-1);
}

void	write_line(int fd, char *line, int want_expand, t_shell *shell)
{
	char	*out;

	if (want_expand)
		out = expand_fragment(line, shell);
	else
		out = ft_strdup(line);
	write(fd, out, ft_strlen(out));
	write(fd, "\n", 1);
	free(out);
}

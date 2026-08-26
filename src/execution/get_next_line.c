/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   get_next_line.c                                    :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/09/04 15:26:08 by fnasser           #+#    #+#             */
/*   Updated: 2025/09/04 15:26:15 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static char	*readfd(int fd, char *line)
{
	char		*save;
	ssize_t		countread;

	save = ft_calloc(BUFFER_SIZE + 1, sizeof(char));
	if (!save)
		return (free(line), NULL);
	countread = 1;
	while (countread > 0 && !ft_strchr(line, '\n'))
	{
		countread = read(fd, save, BUFFER_SIZE);
		if (countread > 0)
		{
			save[countread] = '\0';
			line = ft_strjoin_gnl(line, save);
			if (!line)
				return (free(save), free(line), NULL);
		}
	}
	if (countread == 0 && (!line || !*line))
		return (free(save), free(line), NULL);
	if (countread < 0)
		return (free(line), free(save), NULL);
	return (free(save), line);
}

static char	*init(int fd, char **line)
{
	if (fd < 0 || BUFFER_SIZE <= 0)
		return (NULL);
	if (!*line)
		*line = ft_strduplicate("");
	if (!*line)
		return (NULL);
	*line = readfd(fd, *line);
	if (!*line)
		return (NULL);
	return (*line);
}

char	*get_next_line(int fd)
{
	static char	*line;
	char		*nextline;
	char		*current;

	line = init(fd, &line);
	if (!line)
		return (NULL);
	if (ft_strchr(line, '\n'))
	{
		current = ft_substr(line, 0, ft_strchr(line, '\n') - line + 1);
		nextline = ft_strduplicate(ft_strchr(line, '\n') + 1);
		if (!nextline || !current)
			return (free(line), free(current), NULL);
		free(line);
		line = nextline;
	}
	else
	{
		current = ft_strduplicate(line);
		if (!current)
			return (free(line), NULL);
		free(line);
		line = NULL;
	}
	return (current);
}
// #include <stdio.h>
// #include <fcntl.h>
// int	main(int ac, char **av)
// {
// 	if (ac && av)
//  	{
//  		int fd = open("file.txt", O_RDONLY);
// 		char *curr;
// 		while ((curr = get_next_line(fd)))
// 		{
// 			if (!curr)
// 			{
// 				free(curr);
// 				printf("...");
// 				break;
// 			}
//  			printf("%s", curr);
// 			free(curr);
// 		}
// 		// free(curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// printf("%s", curr);
// 		// free (curr);
//  		close(fd);
//  	}
//  	return (0);
// }
/*int	main(int ac, char **av)
{
 	char *result;
 	int i = 0;
 	if (ac && av)
 	{
  		int fd = open("file.txt", O_RDONLY);
  		while ((result = get_next_line(fd)) != NULL)
 		{
  			printf("Line %d: %s", ++i, result);
  			free(result);
  		}
  		close(fd);
  	}
  	return (0);
}*/

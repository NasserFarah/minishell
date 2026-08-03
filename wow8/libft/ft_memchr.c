/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memchr.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:45:45 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 11:10:23 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

void	*ft_memchr(const void *s, int c, size_t n)
{
	size_t	i;

	i = 0;
	while (i < n)
	{
		if (((const unsigned char *)s)[i] == (unsigned char) c)
		{
			return ((void *)(&((const unsigned char *)s)[i]));
		}
		i++;
	}
	return (NULL);
}
/*
#include <stdio.h>
int	main(void)
{
	const char	str[] = "Hello, 42 Network!";
	char		c = 'N';
	void		*result;
	result = ft_memchr(str, c, ft_strlen(str));
	if (result)
		printf("Character '%c' found at: %s\n", c, (char *)result);
	else
		printf("Character '%c' not found.\n", c);
}
*/

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memset.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:25:27 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/28 04:23:19 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

void	*ft_memset(void *s, int c, size_t n)
{
	size_t	i;

	i = 0;
	while (i < n)
	{
		((unsigned char *)s)[i] = (unsigned char) c;
		i++;
	}
	return (s);
}
/*
#include <stdio.h>
int	main(void)
{
	char buffer[27] = "abcdefjhijklmnopqrstuvwxyz";
	char *ptr = (unsigned char *)ft_memset(buffer, 'x', 13);
	printf("%s\n", ptr);
}
*/

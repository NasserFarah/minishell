/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memmove.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:47:47 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/28 04:42:43 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

void	*ft_memmove(void *dest, const void *src, size_t n)
{
	size_t	i;

	i = 0;
	if (((unsigned char *)dest) > ((unsigned char *)src))
	{
		while (n > 0)
		{
			n--;
			((unsigned char *)dest)[n] = ((unsigned char *)src)[n];
		}
	}
	else
	{
		while (i < n)
		{
			((unsigned char *)dest)[i] = ((unsigned char *)src)[i];
			i++;
		}
	}
	return (dest);
}
/*
#include <string.h>
#include <stdio.h>
int	main(void)
{
	char buffer[20] = "1234567890";
	printf("ft_memmove: %p\n", ft_memmove(buffer + 2, buffer, 8));
	printf("ft_memmove: %p\n", ft_memmove(NULL, "test", 0));
	printf("memmove: %p\n", memmove(NULL, "test", 0));
}
*/

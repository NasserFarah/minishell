/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memcpy.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:47:22 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/28 04:41:27 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

void	*ft_memcpy(void *dest, const void *src, size_t n)
{
	size_t	i;

	i = 0;
	while (i < n)
	{
		((unsigned char *)dest)[i] = ((unsigned char *)src)[i];
		i++;
	}
	return (dest);
}
/*
#include <stdio.h>
int	main(void)
{
	char	src[] = "blablabla";
	char	dest[20];
	void	*result;

	result = ft_memcpy(dest, src, ft_strlen(src) + 1);
	printf("Return value: %s\n", (char *)result);
}
*/

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strlcat.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/20 07:31:07 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/28 07:04:06 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"
#include <stddef.h>

size_t	ft_strlcat(char *dst, const char *src, size_t size)
{
	size_t	i;
	size_t	j;
	size_t	dstlen;
	size_t	srclen;

	i = 0;
	j = ft_strlen(dst);
	dstlen = j;
	srclen = ft_strlen(src);
	if (size == 0)
		return (srclen);
	while ((src[i] != '\0') && (dstlen + i < size - 1))
	{
		dst[j] = src[i];
		i++;
		j++;
	}
	dst[j] = '\0';
	if (size < dstlen)
		return (srclen + size);
	else
		return (dstlen + srclen);
}
/*
#include <stdio.h>
int	main(void)
{
	char	src[] = "Are u here?";
	char	dst[20] = "Hello, ";
	size_t	ret;

	ret = ft_strlcat(dst, src, sizeof(dst));
	printf("Source     : %s\n", src);
	printf("Destination: %s\n", dst);
	printf("Return     : %zu\n", ret);
}
*/

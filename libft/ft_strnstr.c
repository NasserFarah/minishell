/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strnstr.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/20 08:25:05 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:51:03 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"
#include <stddef.h>

char	*ft_strnstr(const char *big, const char *little, size_t len)
{
	size_t	i;
	size_t	j;

	if (*little == '\0')
		return ((char *)big);
	i = 0;
	while (big[i] != '\0' && i < len)
	{
		j = 0;
		while ((little[j] != '\0') && (big[i + j] == little[j])
			&& (i + j < len))
		{
			j++;
		}
		if (little[j] == '\0')
			return ((char *)(&big[i]));
		i++;
	}
	return (0);
}

/*
#include <stdio.h>

int	main(void)
{
	const char	*big = "This is a simple test string";
	const char	*little = "test";
	const char	*result;

	result = ft_strnstr(big, little, 25);
	if (result)
		printf("Found: %s\n", result);
	else
		printf("Not found\n");

	result = ft_strnstr(big, little, 10);
	if (result)
		printf("Found: %s\n", result);
	else
		printf("Not found\n");

	result = ft_strnstr(big, "", 10);
	if (result)
		printf("Empty little returns: %s\n", result);
	else
		printf("Not found\n");

	return (0);
}
*/

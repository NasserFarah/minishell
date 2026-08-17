/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_memcmp.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:46:39 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 15:18:17 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

int	ft_memcmp(const void *s1, const void *s2, size_t n)
{
	size_t	i;

	i = 0;
	while (i < n)
	{
		if (((unsigned char *)s1)[i] != ((unsigned char *)s2)[i])
			return (((unsigned char *)s1)[i]
				- ((unsigned char *)s2)[i]);
		i++;
	}
	return (0);
}
//
/*

#include <stdio.h>
#include <string.h> // For comparison
int main(void)
{
    char str1[] = "Hello";
    char str2[] = "Hello";
    char str3[] = "Hellp";
    char str4[] = "Hel";

    printf("Test 1 (Equal): ft_memcmp: %d 
    | memcmp: %d\n", ft_memcmp(str1, str2, 5), memcmp(str1, str2, 5));
    printf("Test 2 (Different last char): ft_memcmp: %d 
    | memcmp: %d\n", ft_memcmp(str1, str3, 5), memcmp(str1, str3, 5));
    printf("Test 3 (Partial compare): ft_memcmp: %d 
    | memcmp: %d\n", ft_memcmp(str1, str4, 3), memcmp(str1, str4, 3));
    printf("Test 4 (Zero length): ft_memcmp: %d 
    | memcmp: %d\n", ft_memcmp(str1, str3, 0), memcmp(str1, str3, 0));
    printf("Test 5 (Empty strings): ft_memcmp: %d 
    | memcmp: %d\n", ft_memcmp("", "", 1), memcmp("", "", 1));

    return 0;
}
*/

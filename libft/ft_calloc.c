/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_calloc.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:44:17 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 13:29:26 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"
#include <stdint.h>

void	*ft_calloc(size_t nmemb, size_t size)
{
	void	*ptr;

	if (size != 0 && nmemb > SIZE_MAX / size)
	{
		return (NULL);
	}
	ptr = (void *)malloc(nmemb * size);
	if (!ptr)
	{
		return (NULL);
	}
	ft_bzero(ptr, (nmemb * size));
	return (ptr);
}
/*
#include <stdio.h>
int main(void)
{
    int *arr;
    size_t n = 5;
    size_t size = sizeof(int);

    arr = (int *)ft_calloc(n, size);
    if (!arr)
    {
        printf("ft_calloc failed\n");
        return (1);
    }

    printf("Allocated array initialized with zeros:\n");
    for (size_t i = 0; i < n; i++)
    {
        printf("arr[%zu] = %d\n", i, arr[i]);  // Should all be 0
    }

    free(arr);
    return (0);
}
*/

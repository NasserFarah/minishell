/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strncmp.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/20 08:08:35 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/20 08:23:55 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"
#include <stddef.h>

int	ft_strncmp(const char *s1, const char *s2, size_t n)
{
	size_t	i;

	if (n == 0)
		return (0);
	i = 0;
	while ((i < n) && (s1[i] != '\0') && (s2[i] != '\0') && (s1[i] == s2[i]))
	{
		i++;
	}
	if (i < n)
		return (s1[i] - s2[i]);
	else
		return (0);
}
/*
#include <stdio.h>
int	main(void)
{
	char	*s1 = "Abdullah";
	char	*s2 = "Abdulrahman";

	printf("%d\n", ft_strncmp(s1, s2, 6));
}
*/

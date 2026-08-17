/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strchr.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/12 17:03:59 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/16 03:32:35 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <stddef.h>

char	*ft_strchr(const char *s, int c)
{
	if (!s)
	{
		return (NULL);
	}
	while (*s)
	{
		if (*s == (char) c)
		{
			return ((char *) s);
		}
		s++;
	}
	if (c == 0)
	{
		if (*s == (char) c)
		{
			return ((char *) s);
		}
	}
	return (NULL);
}
/*
#include <stdio.h>
int	main()
{
	printf("%s",ft_strchr("whereisthe( )?",32));
}
*/

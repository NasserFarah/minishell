/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strrchr.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/16 03:38:19 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/28 06:26:06 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */
#include <stddef.h>

char	*ft_strrchr(const char *s, int c)
{
	int	i;

	i = 0;
	while (s[i] != '\0')
		i++;
	if (c == 0)
	{
		if (s[i] == (char) c)
		{
			return ((char *)(&s[i]));
		}
	}
	i--;
	while (i >= 0)
	{
		if (s[i] == (char) c)
		{
			return ((char *)(&s[i]));
		}
		i--;
	}
	return (NULL);
}
/*
#include <stdio.h>
#include <string.h>
int	main()
{
	printf("%s\n",ft_strrchr("whereisthe( )? 123",32));
	printf("%s\n",ft_strrchr("whereisthe( )? 123",0));
	printf("%s\n",strrchr("whereisthe( )? 123",0));
}
*/

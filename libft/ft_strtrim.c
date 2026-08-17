/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strtrim.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 02:42:07 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 15:11:42 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

static int	ft_is_in_set(char c, const char *set)
{
	size_t	i;

	i = 0;
	while (i < ft_strlen(set))
	{
		if (c == set[i])
			return (1);
		i++;
	}
	return (0);
}

char	*ft_strtrim(const char *s1, const char *set)
{
	size_t	begin;
	size_t	end;
	char	*str;

	if (!s1)
		return (NULL);
	begin = 0;
	while (ft_is_in_set(s1[begin], set))
		begin++;
	if (begin == ft_strlen(s1))
	{
		str = (char *)malloc(1);
		if (!str)
			return (NULL);
		str[0] = '\0';
		return (str);
	}
	end = ft_strlen(s1) - 1;
	while (ft_is_in_set(s1[end], set))
		end--;
	return (ft_substr(s1, begin, end - begin + 1));
}

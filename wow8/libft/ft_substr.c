/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_substr.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/28 08:33:59 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 15:21:06 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

char	*ft_substr(char const *s, unsigned int start, size_t len)
{
	size_t	i;
	char	*str;

	if (!s)
		return (NULL);
	if (start >= (unsigned int)ft_strlen(s))
	{
		str = malloc(1);
		if (!str)
			return (NULL);
		return (str[0] = '\0', str);
	}
	if (len > ft_strlen(&s[start]))
		len = ft_strlen(&s[start]);
	str = (char *)malloc(sizeof(char) * (len + 1));
	if (!str)
		return (NULL);
	i = 0;
	while (i < len && s[start + i] != '\0')
	{
		str[i] = s[start + i];
		i++;
	}
	return (str[i] = '\0', str);
}
/*
#include <stdio.h>
#include "libft.h"

int main(void)
{
    char *str = "Hello, 42 Network!";
    char *sub;

    // Test 1: Normal case
    sub = ft_substr(str, 7, 2);  // Should return "42"
    printf("Test 1: %s\n", sub);
    free(sub);

    // Test 2: Substring past the end
    sub = ft_substr(str, 100, 5);  // Should return ""
    printf("Test 2: %s\n", sub);
    free(sub);

    // Test 3: Substring with len longer than available
    sub = ft_substr(str, 7, 20);  // Should return "42 Network!"
    printf("Test 3: %s\n", sub);
    free(sub);

    // Test 4: Substring with start == length of string
    sub = ft_substr(str, ft_strlen(str), 5);  // Should return ""
    printf("Test 4: %s\n", sub);
    free(sub);

    // Test 5: Empty string input
    sub = ft_substr("", 0, 5);  // Should return ""
    printf("Test 5: %s\n", sub);
    free(sub);

    return 0;
}
*/

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strmapi.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 09:31:09 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:39:58 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

char	*ft_strmapi(char const *s, char (*f)(unsigned int, char))
{
	char			*result;
	unsigned int	i;

	if (!s || !f)
		return (NULL);
	i = 0;
	result = malloc(ft_strlen(s) + 1);
	if (!result)
		return (NULL);
	while (s[i] != '\0')
	{
		result[i] = f(i, s[i]);
		i++;
	}	
	result[i] = '\0';
	return (result);
}
/*
#include "libft.h"
#include <stdio.h>

// Example function to use with ft_strmapi
char example_function(unsigned int i, char c)
{
    if (i % 2 == 0)
        return ft_toupper(c);
    else
        return ft_tolower(c);
}

int main(void)
{
    char *original = "HeLLo WoRLd!";
    char *mapped = ft_strmapi(original, example_function);

    if (mapped)
    {
        printf("Original: %s\n", original);
        printf("Mapped  : %s\n", mapped);
        free(mapped);
    }
    else
    {
        printf("Memory allocation failed.\n");
    }

    return 0;
}
*/

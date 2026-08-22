/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_strdup.c                                        :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/23 01:44:58 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:22:38 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

char	*ft_strdup(const char *s)
{
	char	*dest;
	int		i;
	int		len;

	len = 0;
	while (s[len] != '\0')
		len++;
	dest = (char *) malloc(sizeof(char) * (len + 1));
	if (dest == NULL)
		return (NULL);
	i = 0;
	while (i < len)
	{
		dest[i] = s[i];
		i++;
	}
	dest[i] = '\0';
	return (dest);
}
/*
int main(void)
{
    const char *original = "Hello, Libft!";
    char *copy;

    copy = ft_strdup(original);

    if (!copy)
    {
        printf("ft_strdup returned NULL\n");
        return (1);
    }

    printf("Original: \"%s\"\n", original);
    printf("Duplicate: \"%s\"\n", copy);

    free(copy); // don't forget to free the allocated memory
    return (0);
}
*/

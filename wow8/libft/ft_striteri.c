/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_striteri.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 09:54:02 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:25:14 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

void	ft_striteri(char *s, void (*f)(unsigned int, char *))
{
	unsigned int	i;

	i = 0;
	while (s[i] != '\0')
	{
		(*f)(i, &s[i]);
		i++;
	}
}
/*
void to_upper(unsigned int index, char *ch)
{
    if (*ch >= 'a' && *ch <= 'z')
        *ch = *ch - ('a' - 'A');
}

int main(void)
{
    char str[] = "hello, libft!";

    printf("Before: %s\n", str);
    ft_striteri(str, to_upper);
    printf("After:  %s\n", str);

    return (0);
}
*/

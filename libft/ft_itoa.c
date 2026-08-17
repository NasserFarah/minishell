/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_itoa.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 08:48:29 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 13:49:17 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

static int	get_len(int n)
{
	int	len;

	len = 0;
	if (n <= 0)
	{
		len++;
	}
	while (n != 0)
	{
		n /= 10;
		len++;
	}
	return (len);
}

static void	fill_digits(char *str, long nb, int i)
{
	int	tens;

	tens = 1;
	while (nb / tens >= 10)
		tens *= 10;
	while (tens > 0)
	{
		str[i++] = (nb / tens) + '0';
		nb %= tens;
		tens /= 10;
	}
}

char	*ft_itoa(int n)
{
	char	*str;
	long	nb;
	int		len;
	int		i;

	len = get_len(n);
	str = (char *)malloc(sizeof(char) * (len + 1));
	if (!str)
		return (NULL);
	str[len] = '\0';
	i = 0;
	nb = (long)n;
	if (n < 0)
	{
		str[i++] = '-';
		nb = -nb;
	}
	if (n == 0)
		str[len - 1] = '0';
	else
		fill_digits(str, nb, i);
	return (str);
}
/*
#include <stdio.h>
int main(void)
{
    int test_numbers[] = {0, 42, -42, 12345, -12345, 2147483647, -2147483648};
    size_t i = 0;
    char *result;

    while (i < sizeof(test_numbers) / sizeof(test_numbers[0]))
    {
        result = ft_itoa(test_numbers[i]);
        if (result)
        {
            printf("ft_itoa(%d) = \"%s\"\n", test_numbers[i], result);
            free(result);
        }
        else
        {
            printf("ft_itoa(%d) = NULL (allocation failed)\n", test_numbers[i]);
        }
        i++;
    }

    return 0;
}
*/

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_putnbr_fd.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 10:18:40 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:12:12 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

static void	simple_conditions(int nb, int fd)
{
	if (nb == -2147483648)
	{
		write(fd, "-2147483648", 11);
	}
	else if (nb == 0)
	{
		ft_putchar_fd('0', fd);
	}
	else if (nb > 0 && nb <= 9)
	{
		ft_putchar_fd('0' + nb, fd);
	}
	else if (nb >= -9 && nb < 0)
	{
		ft_putchar_fd('-', fd);
		nb = nb * -1;
		ft_putchar_fd('0' + nb, fd);
	}
}

void	ft_putnbr_fd(int n, int fd)
{
	int	tens;

	if (n == -2147483648 || (n >= -9 && n <= 9))
	{
		simple_conditions(n, fd);
	}
	else
	{
		if (n < 0)
		{
			ft_putchar_fd('-', fd);
			n = n * -1;
		}
		tens = 1;
		while (n / tens >= 10)
		{
			tens = tens * 10;
		}
		while (tens > 0)
		{
			ft_putchar_fd('0' + n / tens, fd);
			n = n % tens;
			tens = tens / 10;
		}
	}
}
/*
#include <fcntl.h>     // for open
#include <unistd.h>    // for close, write
#include "libft.h"     // your function declarations

int main(void)
{
    int fd;

    // Write to standard output
    ft_putnbr_fd(12345, 1);
    write(1, "\n", 1);
    ft_putnbr_fd(-12345, 1);
    write(1, "\n", 1);
    ft_putnbr_fd(0, 1);
    write(1, "\n", 1);
    ft_putnbr_fd(-2147483648, 1);
    write(1, "\n", 1);
    ft_putnbr_fd(9, 1);
    write(1, "\n", 1);
    ft_putnbr_fd(-9, 1);
    write(1, "\n", 1);

    // Optional: Write to a file
    fd = open("output.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd != -1)
    {
        ft_putnbr_fd(2025, fd);
        ft_putnbr_fd(-2025, fd);
        ft_putnbr_fd(0, fd);
        close(fd);
    }

    return 0;
}
*/

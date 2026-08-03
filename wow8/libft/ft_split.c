/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_split.c                                         :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/06/29 04:23:17 by abdunass          #+#    #+#             */
/*   Updated: 2025/06/29 14:16:18 by abdunass         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "libft.h"

static int	count_words(char const *s, char c)
{
	int	count;
	int	i;

	count = 0;
	i = 0;
	if (!s || !*s)
		return (count);
	while (s[i] == c)
		i++;
	while (s[i] != '\0')
	{
		while (s[i] != '\0' && s[i] != c)
			i++;
		count++;
		while (s[i] != '\0' && s[i] == c)
			i++;
	}
	return (count);
}

static char	*add_word(char const *s, char c, int begin)
{
	int		i;
	int		len;
	char	*word;

	len = 0;
	while (s[len + begin] != '\0' && s[len + begin] != c)
		len++;
	word = (char *)malloc(sizeof(char) * (len + 1));
	if (!word)
		return (NULL);
	i = 0;
	while (i < len)
	{
		word[i] = s[begin + i];
		i++;
	}
	word[i] = '\0';
	return (word);
}

static char	**ft_malloc(char const *s, char c)
{
	char	**strostr;

	strostr = (char **)malloc((count_words(s, c) + 1) * sizeof(char *));
	if (!strostr)
		return (NULL);
	return (strostr);
}

static char	**ft_free(char **strostr)
{
	int	i;

	i = 0;
	while (strostr[i])
	{
		free(strostr[i]);
		i++;
	}
	free(strostr);
	return (NULL);
}

char	**ft_split(char const *s, char c)
{
	char	**strostr;
	int		i;
	int		j;

	if (!s)
		return (NULL);
	i = 0;
	j = 0;
	strostr = ft_malloc(s, c);
	while (s[i] != '\0')
	{
		while (s[i] != '\0' && s[i] == c)
			i++;
		if (!s[i])
			break ;
		strostr[j] = add_word(s, c, i);
		if (!strostr[j])
			return (ft_free(strostr));
		j++;
		while (s[i] != '\0' && s[i] != c)
			i++;
	}
	strostr[j] = NULL;
	return (strostr);
}
/*
int main(void)
{
    char const *str = "  hello   world this is   libft  ";
    char sep = ' ';
    char **result = ft_split(str, sep);
    int i = 0;

    if (!result)
    {
        printf("ft_split returned NULL\n");
        return (1);
    }

    while (result[i])
    {
        printf("result[%d] = \"%s\"\n", i, result[i]);
        free(result[i]);
        i++;
    }
    free(result);

    return (0);
}
*/

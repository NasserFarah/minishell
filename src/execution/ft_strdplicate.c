#include "minishell.h"

char	*ft_strdup(const char *s)
{
	char	*dest;
	int		i;
	int		len;

    if (s == NULL)
		return (NULL);
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
/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   builtin_cd_path.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/09/02 22:10:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/09/02 22:10:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	pop_seg(char *out, size_t *len)
{
	while (*len > 1 && out[*len - 1] != '/')
		(*len)--;
	if (*len > 1)
		(*len)--;
	out[*len] = '\0';
}

static void	add_seg(char *out, size_t *len, const char *seg, size_t n)
{
	if (*len > 1)
		out[(*len)++] = '/';
	ft_memcpy(out + *len, seg, n);
	*len += n;
	out[*len] = '\0';
}

static void	canon_seg(char *out, size_t *len, const char *seg, size_t n)
{
	if (n == 2 && seg[0] == '.' && seg[1] == '.')
		pop_seg(out, len);
	else if (n > 0 && !(n == 1 && seg[0] == '.'))
		add_seg(out, len, seg, n);
}

char	*cd_canonical(const char *abs)
{
	char	*out;
	size_t	len;
	size_t	i;
	size_t	start;

	if (!abs)
		return (NULL);
	out = malloc(ft_strlen(abs) + 2);
	if (!out)
		return (NULL);
	out[0] = '/';
	out[1] = '\0';
	len = 1;
	i = 0;
	while (abs[i])
	{
		while (abs[i] == '/')
			i++;
		start = i;
		while (abs[i] && abs[i] != '/')
			i++;
		canon_seg(out, &len, abs + start, i - start);
	}
	return (out);
}

char	*cd_absolute(t_shell *shell, const char *target)
{
	char	*tmp;
	char	*abs;

	if (target[0] == '/')
		return (ft_strduplicate(target));
	if (!shell->cwd)
		return (NULL);
	tmp = ft_strjoin(shell->cwd, "/");
	if (!tmp)
		return (NULL);
	abs = ft_strjoin(tmp, target);
	free(tmp);
	return (abs);
}

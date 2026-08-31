/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell_input.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/26 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/26 00:00:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	build_prompt(char *prompt)
{
	char	cwd[4096];
	char	*color;

	if (!getcwd(cwd, sizeof(cwd)))
		cwd[0] = '\0';
	color = PROMPT_GREEN;
	prompt[0] = '\0';
	ft_strlcat(prompt, color, 4096);
	ft_strlcat(prompt, cwd, 4096);
	ft_strlcat(prompt, "$ ", 4096);
	ft_strlcat(prompt, PROMPT_RESET, 4096);
}

char	*read_noninteractive_line(void)
{
	char	*line;
	size_t	len;

	line = get_next_line(STDIN_FILENO);
	if (!line)
		return (NULL);
	len = ft_strlen(line);
	if (len > 0 && line[len - 1] == '\n')
		line[len - 1] = '\0';
	return (line);
}

char	*read_interactive_line(char *prompt)
{
	char	*line;

	build_prompt(prompt);
	line = readline(prompt);
	if (!line)
	{
		ft_putstr_fd("exit\n", STDOUT_FILENO);
		return (NULL);
	}
	if (*line)
		add_history(line);
	return (line);
}

void	init_shell(t_shell *shell, char **argv, char **envp)
{
	static char	c[4096];
	char		*pat;

	(void)argv;
	pat = malloc(BUFFER_SIZE * sizeof(pat));
	ft_strlcpy(pat,
		"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
		BUFFER_SIZE);
	shell->env = env_init(envp);
	env_set(&shell->env, "PWD", getcwd(c, 4096));
	if (!env_get(shell->env, "PATH"))
		env_set(&shell->env, "PATH", pat);
	shell->exit_status = 0;
	shell->interactive = isatty(STDIN_FILENO);
	shell->should_exit = 0;
	free(pat);
}

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell_input.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/26 00:00:00 by fnasser           #+#    #+#             */
/*   Updated: 2026/09/02 22:10:00 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	build_prompt(t_shell *shell, char *prompt)
{
	prompt[0] = '\0';
	ft_strlcat(prompt, PROMPT_GREEN, 4096);
	if (shell->cwd)
		ft_strlcat(prompt, shell->cwd, 4096);
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

char	*read_interactive_line(t_shell *shell, char *prompt)
{
	char	*line;

	build_prompt(shell, prompt);
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

static char	*initial_cwd(t_env *env)
{
	char		cwd[4096];
	char		*pwd;
	struct stat	here;
	struct stat	named;

	pwd = env_get(env, "PWD");
	if (pwd && pwd[0] == '/' && stat(pwd, &named) == 0
		&& stat(".", &here) == 0 && named.st_dev == here.st_dev
		&& named.st_ino == here.st_ino)
		return (ft_strduplicate(pwd));
	if (getcwd(cwd, sizeof(cwd)))
		return (ft_strduplicate(cwd));
	if (pwd && pwd[0] == '/')
		return (ft_strduplicate(pwd));
	return (NULL);
}

void	init_shell(t_shell *shell, char **argv, char **envp)
{
	char	*pat;

	(void)argv;
	pat = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
	shell->env = env_init(envp);
	shell->cwd = initial_cwd(shell->env);
	if (shell->cwd)
		env_set(&shell->env, "PWD", shell->cwd);
	if (!env_get(shell->env, "PATH"))
		env_set(&shell->env, "PATH", pat);
	shell->exit_status = 0;
	shell->interactive = isatty(STDIN_FILENO);
	shell->should_exit = 0;
}

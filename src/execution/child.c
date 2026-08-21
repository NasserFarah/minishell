/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   child.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/30 00:00:00 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/30 00:00:00 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	child_fail(const char *name, int code)
{
	if (code == 127)
	{
		ft_putstr_fd("minishell: ", STDERR_FILENO);
		ft_putstr_fd((char *)name, STDERR_FILENO);
		ft_putstr_fd(": command not found\n", STDERR_FILENO);
	}
	else
		perror(name);
	exit(code);
}

static void	exec_fail(const char *name)
{
	struct stat	st;

	ft_putstr_fd("minishell: ", STDERR_FILENO);
	ft_putstr_fd((char *)name, STDERR_FILENO);
	if ((errno == EACCES || errno == EISDIR)
		&& stat(name, &st) == 0 && S_ISDIR(st.st_mode))
	{
		ft_putstr_fd(": Is a directory\n", STDERR_FILENO);
		exit(126);
	}
	if (errno == ENOENT)
	{
		ft_putstr_fd(": No such file or directory\n", STDERR_FILENO);
		exit(127);
	}
	if (errno == EACCES)
	{
		ft_putstr_fd(": Permission denied\n", STDERR_FILENO);
		exit(126);
	}
	ft_putstr_fd(": ", STDERR_FILENO);
	ft_putstr_fd(strerror(errno), STDERR_FILENO);
	ft_putstr_fd("\n", STDERR_FILENO);
	exit(126);
}

void	run_child(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx)
{
	char	*path;
	char	**argv;
	char	**envp;
	int		code;

	signals_child_default();
	wire_pipes(pl, idx);
	close_pipes(pl);
	if (apply_redirs(cmd->redirs) == -1)
		exit(1);
	if (!cmd->args)
		exit(0);
	if (is_builtin(cmd->args->value))
		exit(run_builtin(cmd, shell));
	path = resolve_executable(cmd->args->value, shell->env, &code);
	if (!path)
		child_fail(cmd->args->value, code);
	argv = build_argv(cmd->args);
	envp = build_envp(shell->env);
	execve(path, argv, envp);
	exec_fail(path);
}

/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   child.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: fnasser <marvin@42.fr>                     +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/28 03:53:14 by fnasser           #+#    #+#             */
/*   Updated: 2026/08/28 03:53:16 by fnasser          ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

static void	child_exit(t_child *ctx, int code)
{
	free_cmd(ctx->shell->pipeline);
	free_env(ctx->shell->env);
	free_pipeline(ctx->pl);
	get_next_line(-1);
	exit(code);
}

static void	child_fail(t_child *ctx, const char *name, int code)
{
	if (code == 127)
	{
		ft_putstr_fd("minishell: ", STDERR_FILENO);
		ft_putstr_fd((char *)name, STDERR_FILENO);
		ft_putstr_fd(": command not found\n", STDERR_FILENO);
	}
	else
		perror(name);
	child_exit(ctx, code);
}

static void	exec_fail(t_child *ctx, char *path, char **argv, char **envp)
{
	int	code;

	code = report_exec_error(path);
	free(path);
	free(argv);
	free_envp(envp);
	child_exit(ctx, code);
}

static void	prepare_child(t_pipeline *pl, int idx)
{
	signals_child_default();
	wire_pipes(pl, idx);
	close_pipes(pl);
}

void	run_child(t_cmd *cmd, t_shell *shell, t_pipeline *pl, int idx)
{
	t_child	ctx;
	char	*path;
	char	**argv;
	char	**envp;
	int		code;

	ctx.shell = shell;
	ctx.pl = pl;
	prepare_child(pl, idx);
	if (apply_redirs(cmd->redirs) == -1)
		child_exit(&ctx, 1);
	if (!cmd->args)
		child_exit(&ctx, 0);
	if (is_builtin(cmd->args->value))
		child_exit(&ctx, run_builtin(cmd, shell));
	path = resolve_executable(cmd->args->value, shell->env, &code);
	if (!path)
		child_fail(&ctx, cmd->args->value, code);
	argv = build_argv(cmd->args);
	envp = build_envp(shell->env);
	execve(path, argv, envp);
	exec_fail(&ctx, path, argv, envp);
}

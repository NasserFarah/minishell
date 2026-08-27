/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   shell.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abdunass <marvin@42.fr>                  +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/07/27 22:43:27 by abdunass        #+#    #+#             */
/*   Updated: 2026/07/27 22:43:27 by abdunass       ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "minishell.h"

char	*get_last_last_arg(t_shell *shell)
{
	t_cmd	*pipeline;
	t_token	*args;

	pipeline = shell->pipeline;
	if (!pipeline)
		return (NULL);
	while (pipeline)
	{
		if (pipeline->next == NULL)
		{
			args = pipeline->args;
			while (args)
			{
				if (args->next == NULL)
					return (args->value);
				args = args->next;
			}
		}
		pipeline = pipeline->next;
	}
	return (NULL);
}

static void	run_tokens(t_shell *shell)
{
	char	*last_arg;

	shell->pipeline = parse(&shell->tokens);
	if (shell->pipeline)
	{
		expand(shell);
		execute(shell);
	}
	last_arg = get_last_last_arg(shell);
	if (last_arg != NULL)
		env_set(&shell->env, "_", last_arg);
	free_cmd(shell->pipeline);
	shell->pipeline = NULL;
}

static void	process_line(t_shell *shell, char *line)
{
	int	tok_error;

	tok_error = 0;
	shell->tokens = tokenize(line, &tok_error);
	free(line);
	if (shell->tokens && !validate_tokens(shell->tokens))
	{
		shell->exit_status = 2;
		free_tokens(shell->tokens);
		shell->tokens = NULL;
	}
	else if (shell->tokens)
		run_tokens(shell);
	else if (tok_error)
		shell->exit_status = 2;
}

void	shell_loop(t_shell *shell)
{
	char	*line;
	char	prompt[4096];

	while (1)
	{
		if (shell->interactive)
			line = read_interactive_line(prompt);
		else
			line = read_noninteractive_line();
		if (!line)
			break ;
		process_line(shell, line);
		if (shell->should_exit)
			break ;
	}
	rl_clear_history();
}

void	free_shell(t_shell *shell)
{
	free_env(shell->env);
}

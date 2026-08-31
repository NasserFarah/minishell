NAME		= minishell
CC			= cc
CFLAGS		= -Wall -Wextra -Werror -g -g3
RM			= rm -f

SRCDIR		= src
OBJDIR		= obj
INCDIR		= inc
LIBFT_DIR	= libft
LIBFT		= $(LIBFT_DIR)/libft.a

INCLUDES	= -I$(INCDIR) -I$(LIBFT_DIR)
LIBS		= -lreadline

SRCS		= src/main/main.c \
			  src/shell/shell.c \
			  src/shell/shell_input.c \
			  src/shell/signals.c \
			  src/shell/signals_exec.c \
			  src/env/env.c \
			  src/env/env_mutate.c \
			  src/tokenizer/tokenizer.c \
			  src/tokenizer/tokenizer_word.c \
			  src/tokenizer/tokenizer_utils.c \
			  src/tokenizer/tokenizer_validate.c \
			  src/tokenizer/tokenizer_validate_utils.c \
			  src/parser/parser.c \
			  src/parser/parser_redir.c \
			  src/parser/parser_utils.c \
			  src/expansion/expansion.c \
			  src/expansion/expand_var.c \
			  src/expansion/expand_var_utils.c \
			  src/expansion/expand_split.c \
			  src/expansion/expand_redirs.c \
			  src/expansion/tilde.c \
			  src/expansion/tilde_utils.c \
			  src/execution/execute.c \
			  src/execution/path.c \
			  src/execution/exec_arrays.c \
			  src/execution/redirect.c \
			  src/execution/heredoc.c \
			  src/execution/heredoc_utils.c \
			  src/execution/pipeline.c \
			  src/execution/child.c \
			  src/execution/exec_error.c \
			  src/execution/wait_status.c \
			  src/execution/standalone.c \
			  src/execution/ft_strdplicate.c \
			  src/execution/get_next_line.c \
			  src/execution/get_next_line_utils.c \
			  src/builtin_functions/builtins.c \
			  src/builtin_functions/builtin_utils.c \
			  src/builtin_functions/builtin_echo.c \
			  src/builtin_functions/builtin_pwd.c \
			  src/builtin_functions/builtin_cd.c \
			  src/builtin_functions/builtin_env.c \
			  src/builtin_functions/builtin_export.c \
			  src/builtin_functions/builtin_export_print.c \
			  src/builtin_functions/builtin_unset.c \
			  src/builtin_functions/builtin_exit.c

OBJS		= $(SRCS:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

all: $(NAME)

$(NAME): $(LIBFT) $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) $(LIBFT) $(LIBS) -o $(NAME)

$(LIBFT):
	$(MAKE) -C $(LIBFT_DIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	$(RM) -r $(OBJDIR)
	$(MAKE) -C $(LIBFT_DIR) clean

fclean: clean
	$(RM) $(NAME)
	$(MAKE) -C $(LIBFT_DIR) fclean

re: fclean all

.PHONY: all clean fclean re

NAME = minishell
CC = cc
CFLAGS = -Wall -Werror -Wextra -g
LIBRARIES = -lreadline
SRC = SRC/free_utils.c SRC/lex.c SRC/libft_utils.c SRC/loop.c SRC/main.c \
	SRC/parse.c SRC/tkn_action.c SRC/tokenizer.c
OBJ = $(SRC:.c=.o)
RM = rm -rf
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
all: $(NAME)
$(NAME): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) $(LIBRARIES) -o $(NAME)
clean:
	$(RM) $(OBJ)
fclean: clean
	$(RM) $(NAME)
re: fclean all

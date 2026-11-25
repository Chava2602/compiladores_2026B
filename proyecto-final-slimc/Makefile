CC     = gcc
CFLAGS = -Wall -Wno-unused-function

slimc: lexer.l parser.y tabla_simbolos.c tabla_simbolos.h
	bison -d -Wall parser.y
	flex lexer.l
	$(CC) $(CFLAGS) -o slimc parser.tab.c lex.yy.c tabla_simbolos.c

test: slimc
	-./slimc correcto.c
	-./slimc errores.c

clean:
	rm -f slimc parser.tab.c parser.tab.h lex.yy.c

.PHONY: test clean

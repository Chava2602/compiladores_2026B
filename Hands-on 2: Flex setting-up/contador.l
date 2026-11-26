/* contador.l — Lexer mínimo para verificar que Flex quedó instalado.
   Cuenta líneas, palabras, números y caracteres de un archivo de texto. */
%option noyywrap noinput nounput

%{
#include <stdio.h>
static int lineas, palabras, numeros, caracteres;
%}

%%
[0-9]+              { ++numeros;  caracteres += yyleng; }
[A-Za-z]+           { ++palabras; caracteres += yyleng; }
\n                  { ++lineas;   ++caracteres; }
.                   { ++caracteres; }
%%

int main(int argc, char **argv)
{
    if (argc > 1 && !(yyin = fopen(argv[1], "r"))) {
        perror(argv[1]);
        return 1;
    }
    yylex();
    printf("Lineas: %d | Palabras: %d | Numeros: %d | Caracteres (bytes): %d\n",
           lineas, palabras, numeros, caracteres);
    return 0;
}

/* lexer.l — Analizador léxico de SlimC (Flex). */
%option noyywrap noinput nounput yylineno
%x COMENTARIO

%{
#include <stdio.h>
#include <string.h>
#include "tabla_simbolos.h"
#include "parser.tab.h"

/* Cada token lleva la línea en la que aparece (para @n.first_line en Bison). */
#define YY_USER_ACTION yylloc.first_line = yylineno;

static int linea_comentario;

static void error_lexico(int linea, const char *mensaje, const char *texto)
{
    printf("Error léxico en línea %d: %s '%s'.\n", linea, mensaje, texto);
    ++errores_lexicos;
}

/* Copia el nombre de la librería que está entre < > o entre comillas. */
static void copiar_libreria(void)
{
    char *ini = strpbrk(yytext, "<\"");
    size_t len = strlen(ini + 1) - 1;
    if (len >= sizeof yylval.nombre) len = sizeof yylval.nombre - 1;
    memcpy(yylval.nombre, ini + 1, len);
    yylval.nombre[len] = '\0';
}
%}

ID      [A-Za-z_][A-Za-z_0-9]*
D       [0-9]
EXP     [eE][+-]?{D}+
REAL    ({D}+"."{D}*|"."{D}+)({EXP})?|{D}+{EXP}
LIB     [A-Za-z0-9_./]+

%%

 /* ---------- Comentarios (no alteran yylineno: flex cuenta cada \n) ---------- */
"//"[^\n]*                      ;
"/*"                            { linea_comentario = yylineno; BEGIN(COMENTARIO); }
<COMENTARIO>"*/"                BEGIN(INITIAL);
<COMENTARIO>[^*\n]+             ;
<COMENTARIO>"*"                 ;
<COMENTARIO>\n                  ;
<COMENTARIO><<EOF>>             {
                                    error_lexico(linea_comentario, "comentario sin cerrar", "/*");
                                    BEGIN(INITIAL);
                                    yyterminate();
                                }

 /* ---------- Directivas de preprocesador ---------- */
"#include"[ \t]*"<"{LIB}">"     { copiar_libreria(); return INCLUDE; }
"#include"[ \t]*\"{LIB}\"       { copiar_libreria(); return INCLUDE; }
"#define"                       return DEFINE;
"#"{ID}?                        error_lexico(yylineno, "directiva no reconocida", yytext);

 /* ---------- Palabras reservadas ---------- */
"int"                           return INT;
"double"                        return DOUBLE;
"const"                         return CONST;
"return"                        return RETURN;
"main"                          return MAIN;
"printf"                        return PRINTF;
"if"                            return IF;
"else"                          return ELSE;
"while"                         return WHILE;

 /* ---------- Operadores relacionales y lógicos de dos caracteres ---------- */
"=="                            return EQ;
"!="                            return NE;
"<="                            return LE;
">="                            return GE;
"&&"                            return AND;
"||"                            return OR;

 /* ---------- Literales e identificadores ---------- */
{REAL}                          return DECIMAL;
{D}+                            return ENTERO;
{D}+{ID}                        error_lexico(yylineno, "identificador mal formado", yytext);
{ID}                            {
                                    if (yyleng >= (int)sizeof yylval.nombre) {
                                        error_lexico(yylineno, "identificador demasiado largo", yytext);
                                        yytext[sizeof yylval.nombre - 1] = '\0';
                                    }
                                    strcpy(yylval.nombre, yytext);
                                    return ID;
                                }
\"([^\"\\\n]|\\.)*\"            return TEXTO;
\"([^\"\\\n]|\\.)*              error_lexico(yylineno, "cadena sin cerrar", yytext);

 /* ---------- Operadores y delimitadores de un carácter ---------- */
[-+*/%=<>!(){};,]               return yytext[0];

[ \t\r\n]+                      ;
.                               error_lexico(yylineno, "carácter no válido", yytext);

%%

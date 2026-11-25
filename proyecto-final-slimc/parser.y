/* parser.y — Analizador sintáctico y semántico de SlimC (Bison). */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tabla_simbolos.h"

int  yylex(void);
void yyerror(const char *mensaje);
extern FILE *yyin;
extern int yylineno;

static int actual = AMBITO_GLOBAL;   /* función cuyo cuerpo se está analizando */
static const char *contexto;         /* "if" / "while" mientras se analiza una condición */

static int  declarar(const char *nombre, Clase clase, Tipo tipo, int linea);
static int  declarar_funcion(const char *nombre, Tipo tipo, int linea);
static void declarar_variable(const char *nombre, Clase clase, Tipo tipo, Tipo inicial, int linea);
static void definir_macro(const char *nombre, Tipo tipo, int linea);
static Tipo usar_variable(const char *nombre, int linea);
static void asignar(const char *nombre, Tipo tipo, int linea);
static Tipo llamar(const char *nombre, const char *args, int linea);
static void retorno(Tipo tipo, int linea);
static Tipo aritmetica(Tipo a, char op, Tipo b, int linea);
static void agregar(char *lista, Tipo tipo);
%}

%locations
%define parse.error verbose

%union {
    char nombre[64];
    char lista[33];
    int  tipo;
}

%token <nombre> ID      "identificador"
%token <nombre> INCLUDE "#include"
%token DEFINE "#define" CONST "const" INT "int" DOUBLE "double" RETURN "return"
%token MAIN "main" PRINTF "printf" IF "if" ELSE "else" WHILE "while"
%token TEXTO "cadena" ENTERO "entero" DECIMAL "decimal"
%token EQ "==" NE "!=" LE "<=" GE ">=" AND "&&" OR "||"

%type <tipo>  tipo literal expresion
%type <lista> argumentos argumentos_opt

%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%precedence '!' UMINUS

%%

/* ===================== Estructura global ===================== */

programa:
      elementos
    ;

/* Directivas, macros, constantes y funciones pueden combinarse libremente. */
elementos:
      %empty
    | elementos elemento
    ;

elemento:
      INCLUDE
        { ts_agregar($1, C_LIBRERIA, T_ERROR, AMBITO_GLOBAL, @1.first_line); }
    | DEFINE ID literal
        { definir_macro($2, $3, @2.first_line); }
    | constante
    | funcion
    | funcion_main
    | error ';'
        { yyerrok; }
    | error '}'
        { yyerrok; actual = AMBITO_GLOBAL; }
    ;

constante:
      CONST tipo ID '=' expresion ';'
        { declarar_variable($3, C_CONSTANTE, $2, $5, @3.first_line); }
    ;

funcion:
      cabecera '(' parametros_opt ')' bloque
        { actual = AMBITO_GLOBAL; }
    ;

cabecera:
      tipo ID
        { actual = declarar_funcion($2, $1, @2.first_line); }
    ;

funcion_main:
      cabecera_main bloque
        { actual = AMBITO_GLOBAL; }
    ;

cabecera_main:
      INT MAIN '(' ')'
        { actual = declarar_funcion("main", T_INT, @2.first_line); }
    ;

parametros_opt:
      %empty
    | parametros
    ;

parametros:
      parametro
    | parametros ',' parametro
    ;

parametro:
      tipo ID
        {
            declarar($2, C_PARAMETRO, $1, @2.first_line);
            ts_agregar_parametro(actual, $1);
        }
    ;

tipo:
      INT    { $$ = T_INT; }
    | DOUBLE { $$ = T_DOUBLE; }
    ;

/* ===================== Sentencias ===================== */

bloque:
      '{' sentencias '}'
    ;

sentencias:
      %empty
    | sentencias sentencia
    ;

sentencia:
      tipo ID ';'
        { declarar_variable($2, C_VARIABLE, $1, T_ERROR, @2.first_line); }
    | tipo ID '=' expresion ';'
        { declarar_variable($2, C_VARIABLE, $1, $4, @2.first_line); }
    | constante
    | ID '=' expresion ';'
        { asignar($1, $3, @1.first_line); }
    | ID '(' argumentos_opt ')' ';'
        { llamar($1, $3, @1.first_line); }
    | PRINTF '(' TEXTO mas_argumentos ')' ';'
    | RETURN expresion ';'
        { retorno($2, @1.first_line); }
    | seleccion
    | seleccion ELSE bloque
    | iteracion
    | error ';'
        { yyerrok; }
    ;

/* La condición se analiza con "contexto" activo para personalizar los errores. */
seleccion:
      IF '(' { contexto = "if"; } expresion ')' { contexto = NULL; } bloque
    ;

iteracion:
      WHILE '(' { contexto = "while"; } expresion ')' { contexto = NULL; } bloque
    ;

/* ===================== Expresiones ===================== */

argumentos_opt:
      %empty {  $$[0] = '\0'; }
    | argumentos  { strcpy($$, $1); }
    ;

argumentos:
      expresion                { $$[0] = '\0'; agregar($$, $1); }
    | argumentos ',' expresion { strcpy($$, $1); agregar($$, $3); }
    ;

mas_argumentos:
      %empty
    | mas_argumentos ',' expresion
    ;

literal:
      ENTERO  { $$ = T_INT; }
    | DECIMAL { $$ = T_DOUBLE; }
    ;

expresion:
      literal                      { $$ = $1; }
    | ID                           { $$ = usar_variable($1, @1.first_line); }
    | ID '(' argumentos_opt ')'    { $$ = llamar($1, $3, @1.first_line); }
    | '(' expresion ')'            { $$ = $2; }
    | '-' expresion %prec UMINUS   { $$ = $2; }
    | '!' expresion                { $$ = T_INT; }
    | expresion '+' expresion      { $$ = aritmetica($1, '+', $3, @2.first_line); }
    | expresion '-' expresion      { $$ = aritmetica($1, '-', $3, @2.first_line); }
    | expresion '*' expresion      { $$ = aritmetica($1, '*', $3, @2.first_line); }
    | expresion '/' expresion      { $$ = aritmetica($1, '/', $3, @2.first_line); }
    | expresion '%' expresion      { $$ = aritmetica($1, '%', $3, @2.first_line); }
    | expresion '<' expresion      { $$ = T_INT; }
    | expresion '>' expresion      { $$ = T_INT; }
    | expresion LE expresion       { $$ = T_INT; }
    | expresion GE expresion       { $$ = T_INT; }
    | expresion EQ expresion       { $$ = T_INT; }
    | expresion NE expresion       { $$ = T_INT; }
    | expresion AND expresion      { $$ = T_INT; }
    | expresion OR expresion       { $$ = T_INT; }
    ;

%%

/* ===================== Acciones semánticas ===================== */

static const char *nombre_ambito(void)
{
    return actual == AMBITO_GLOBAL ? "global" : ts_simbolo(actual)->nombre;
}

/* Regla de compatibilidad: se admite int -> double, pero no double -> int. */
static int compatible(Tipo destino, Tipo origen)
{
    return destino == T_ERROR || origen == T_ERROR || destino == origen
        || (destino == T_DOUBLE && origen == T_INT);
}

static int declarar(const char *nombre, Clase clase, Tipo tipo, int linea)
{
    int previo = ts_buscar_local(nombre, actual);
    if (previo >= 0) {
        error_semantico(linea, "el símbolo '%s' ya está declarado en el ámbito '%s' (línea %d)",
                        nombre, nombre_ambito(), ts_simbolo(previo)->linea);
        return previo;
    }
    return ts_agregar(nombre, clase, tipo, actual, linea);
}

static int declarar_funcion(const char *nombre, Tipo tipo, int linea)
{
    if (ts_buscar_local(nombre, AMBITO_GLOBAL) >= 0)
        error_semantico(linea, "el símbolo '%s' ya está declarado en el ámbito 'global'", nombre);
    /* Siempre se crea una entrada nueva para poder analizar el cuerpo con su propio ámbito. */
    return ts_agregar(nombre, C_FUNCION, tipo, AMBITO_GLOBAL, linea);
}

static void declarar_variable(const char *nombre, Clase clase, Tipo tipo, Tipo inicial, int linea)
{
    if (!compatible(tipo, inicial))
        error_semantico(linea, "tipo incompatible al inicializar '%s' (se esperaba '%s', se recibió '%s')",
                        nombre, tipo_nombre(tipo), tipo_nombre(inicial));
    declarar(nombre, clase, tipo, linea);
}

static void definir_macro(const char *nombre, Tipo tipo, int linea)
{
    int previo = ts_buscar_local(nombre, AMBITO_GLOBAL);
    if (previo >= 0) {
        if (ts_simbolo(previo)->clase == C_MACRO)
            error_semantico(linea, "macro '%s' ya definida", nombre);
        else
            error_semantico(linea, "el símbolo '%s' ya está declarado en el ámbito 'global'", nombre);
        return;
    }
    ts_agregar(nombre, C_MACRO, tipo, AMBITO_GLOBAL, linea);
}

static void no_declarada(const char *nombre, int linea)
{
    if (contexto)
        error_semantico(linea, "variable '%s' no declarada en condición '%s'", nombre, contexto);
    else
        error_semantico(linea, "variable '%s' no declarada en el ámbito actual", nombre);
}

static Tipo usar_variable(const char *nombre, int linea)
{
    int i = ts_buscar(nombre, actual);
    if (i < 0) { no_declarada(nombre, linea); return T_ERROR; }
    if (ts_simbolo(i)->clase == C_FUNCION) {
        error_semantico(linea, "'%s' es una función y se usó como variable", nombre);
        return T_ERROR;
    }
    return ts_simbolo(i)->tipo;
}

static void asignar(const char *nombre, Tipo tipo, int linea)
{
    int i = ts_buscar(nombre, actual);
    if (i < 0) { no_declarada(nombre, linea); return; }
    Simbolo *s = ts_simbolo(i);
    if (s->clase == C_CONSTANTE)
        error_semantico(linea, "no se puede asignar un valor a la constante '%s'", nombre);
    else if (s->clase == C_MACRO)
        error_semantico(linea, "no se puede asignar un valor a la macro '%s'", nombre);
    else if (s->clase == C_FUNCION)
        error_semantico(linea, "no se puede asignar un valor a la función '%s'", nombre);
    else if (!compatible(s->tipo, tipo))
        error_semantico(linea, "tipo incompatible en asignación a '%s' (se esperaba '%s', se recibió '%s')",
                        nombre, tipo_nombre(s->tipo), tipo_nombre(tipo));
}

static Tipo llamar(const char *nombre, const char *args, int linea)
{
    int i = ts_buscar(nombre, actual);
    if (i < 0) {
        error_semantico(linea, "función '%s' no declarada", nombre);
        return T_ERROR;
    }
    Simbolo *f = ts_simbolo(i);
    if (f->clase != C_FUNCION) {
        error_semantico(linea, "'%s' no es una función", nombre);
        return T_ERROR;
    }
    int recibidos = (int)strlen(args);
    if (recibidos != f->aridad) {
        error_semantico(linea, "la función '%s' espera %d argumento(s), pero recibió %d",
                        nombre, f->aridad, recibidos);
        return f->tipo;
    }
    for (int k = 0; k < recibidos; ++k) {
        Tipo esperado = tipo_de_letra(f->firma[k]), recibido = tipo_de_letra(args[k]);
        if (!compatible(esperado, recibido))
            error_semantico(linea, "tipo incompatible en argumento %d de '%s' (se esperaba '%s', se recibió '%s')",
                            k + 1, nombre, tipo_nombre(esperado), tipo_nombre(recibido));
    }
    return f->tipo;
}

static void retorno(Tipo tipo, int linea)
{
    if (actual == AMBITO_GLOBAL) return;
    Simbolo *f = ts_simbolo(actual);
    if (!compatible(f->tipo, tipo))
        error_semantico(linea, "tipo de retorno incompatible en '%s' (se esperaba '%s', se recibió '%s')",
                        f->nombre, tipo_nombre(f->tipo), tipo_nombre(tipo));
}

static Tipo aritmetica(Tipo a, char op, Tipo b, int linea)
{
    if (a == T_ERROR || b == T_ERROR) return T_ERROR;
    if (op == '%' && (a != T_INT || b != T_INT)) {
        error_semantico(linea, "el operador %% requiere operandos int");
        return T_ERROR;
    }
    return (a == T_DOUBLE || b == T_DOUBLE) ? T_DOUBLE : T_INT;
}

static void agregar(char *lista, Tipo tipo)
{
    size_t n = strlen(lista);
    if (n < MAX_PARAMS) { lista[n] = letra_de_tipo(tipo); lista[n + 1] = '\0'; }
}

/* ===================== Errores sintácticos ===================== */

/* Traduce el mensaje de Bison ("syntax error, unexpected X, expecting Y or Z"). */
void yyerror(const char *mensaje)
{
    static const char *de[]   = { "syntax error, ", "unexpected ", "expecting ", " or ", "end of file" };
    static const char *a[]    = { "",               "no se esperaba ", "se esperaba ", " o ", "fin de archivo" };
    char salida[512] = "";
    const char *p = mensaje;
    while (*p && strlen(salida) < sizeof salida - 32) {
        int hecho = 0;
        for (size_t k = 0; k < sizeof de / sizeof *de; ++k)
            if (strncmp(p, de[k], strlen(de[k])) == 0) {
                strcat(salida, a[k]);
                p += strlen(de[k]);
                hecho = 1;
                break;
            }
        if (!hecho) strncat(salida, p++, 1);
    }
    printf("Error sintáctico en línea %d: %s.\n", yylloc.first_line, salida);
    ++errores_sintacticos;
}

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Uso: %s archivo.c\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror(argv[1]); return 1; }

    printf("SlimC Analyzer — analizando '%s'\n\n", argv[1]);
    yyparse();
    fclose(yyin);

    if (ts_buscar_local("main", AMBITO_GLOBAL) < 0)
        error_semantico(yylineno, "no se encontró la función 'main'");

    ts_imprimir();

    int total = errores_lexicos + errores_sintacticos + errores_semanticos;
    printf("\nErrores léxicos:     %d\n", errores_lexicos);
    printf("Errores sintácticos: %d\n", errores_sintacticos);
    printf("Errores semánticos:  %d\n", errores_semanticos);
    printf("Total de errores:    %d\n", total);
    puts(total == 0 ? "\nResultado: ACCEPT" : "\nResultado: REJECT");
    return total != 0;
}

/* tabla_simbolos.c — Implementación de la tabla de símbolos de SlimC. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "tabla_simbolos.h"

int errores_lexicos, errores_sintacticos, errores_semanticos;

static Simbolo tabla[MAX_SIMBOLOS];
static int     total;

int ts_agregar(const char *nombre, Clase clase, Tipo tipo, int ambito, int linea)
{
    if (total == MAX_SIMBOLOS) {
        fprintf(stderr, "Tabla de símbolos llena (%d entradas).\n", MAX_SIMBOLOS);
        exit(2);
    }
    Simbolo *s = &tabla[total];
    snprintf(s->nombre, sizeof s->nombre, "%s", nombre);
    s->clase     = clase;
    s->tipo      = tipo;
    s->ambito    = ambito;
    s->aridad    = 0;
    s->firma[0]  = '\0';
    s->constante = (clase == C_CONSTANTE || clase == C_MACRO);
    s->linea     = linea;
    return total++;
}

int ts_buscar_local(const char *nombre, int ambito)
{
    for (int i = 0; i < total; ++i)
        if (tabla[i].ambito == ambito && tabla[i].clase != C_LIBRERIA
            && strcmp(tabla[i].nombre, nombre) == 0)
            return i;
    return -1;
}

int ts_buscar(const char *nombre, int ambito)
{
    int i = ambito != AMBITO_GLOBAL ? ts_buscar_local(nombre, ambito) : -1;
    return i >= 0 ? i : ts_buscar_local(nombre, AMBITO_GLOBAL);
}

Simbolo *ts_simbolo(int indice) { return &tabla[indice]; }

void ts_agregar_parametro(int funcion, Tipo tipo)
{
    Simbolo *f = &tabla[funcion];
    if (f->aridad == MAX_PARAMS) {
        fprintf(stderr, "Máximo %d parámetros por función.\n", MAX_PARAMS);
        exit(2);
    }
    f->firma[f->aridad++] = letra_de_tipo(tipo);
    f->firma[f->aridad]   = '\0';
}

const char *tipo_nombre(Tipo tipo)
{
    return tipo == T_INT ? "int" : tipo == T_DOUBLE ? "double" : "?";
}

char letra_de_tipo(Tipo tipo) { return tipo == T_INT ? 'i' : tipo == T_DOUBLE ? 'd' : '?'; }
Tipo tipo_de_letra(char l)    { return l == 'i' ? T_INT : l == 'd' ? T_DOUBLE : T_ERROR; }

static const char *clase_nombre(Clase c)
{
    static const char *nombres[] = {
        "libreria", "macro", "constante", "funcion", "parametro", "variable"
    };
    return nombres[c];
}

void ts_imprimir(void)
{
    puts("\n================================ TABLA DE SIMBOLOS ================================");
    printf("%-3s %-14s %-10s %-7s %-10s %-7s %-6s %-5s\n",
           "#", "Nombre", "Clase", "Tipo", "Ambito", "Aridad", "Const", "Linea");
    puts("-----------------------------------------------------------------------------------");
    for (int i = 0; i < total; ++i) {
        const Simbolo *s = &tabla[i];
        char aridad[8] = "-";
        if (s->clase == C_FUNCION) snprintf(aridad, sizeof aridad, "%d", s->aridad);
        printf("%-3d %-14s %-10s %-7s %-10s %-7s %-6s %-5d\n", i, s->nombre,
               clase_nombre(s->clase),
               s->clase == C_LIBRERIA ? "-" : tipo_nombre(s->tipo),
               s->ambito == AMBITO_GLOBAL ? "global" : tabla[s->ambito].nombre,
               aridad, s->constante ? "si" : "no", s->linea);
    }
    puts("===================================================================================");
}

void error_semantico(int linea, const char *formato, ...)
{
    va_list args;
    printf("Error semántico en línea %d: ", linea);
    va_start(args, formato);
    vprintf(formato, args);
    va_end(args);
    puts(".");
    ++errores_semanticos;
}

/* tabla_simbolos.h — Tabla de símbolos y contadores de errores de SlimC. */
#ifndef TABLA_SIMBOLOS_H
#define TABLA_SIMBOLOS_H

#define MAX_SIMBOLOS  512
#define MAX_NOMBRE    64
#define MAX_PARAMS    32
#define AMBITO_GLOBAL (-1)

typedef enum { T_ERROR = 0, T_INT, T_DOUBLE } Tipo;   /* T_ERROR evita errores en cascada */

typedef enum {
    C_LIBRERIA, C_MACRO, C_CONSTANTE, C_FUNCION, C_PARAMETRO, C_VARIABLE
} Clase;

typedef struct {
    char  nombre[MAX_NOMBRE];
    Clase clase;
    Tipo  tipo;
    int   ambito;                   /* AMBITO_GLOBAL o índice de la función dueña */
    int   aridad;                   /* sólo funciones */
    char  firma[MAX_PARAMS + 1];    /* tipos de los parámetros: "ii" = (int, int) */
    int   constante;                /* 1 para const y #define */
    int   linea;
} Simbolo;

extern int errores_lexicos, errores_sintacticos, errores_semanticos;

/* Agrega siempre un símbolo nuevo y devuelve su índice. */
int      ts_agregar(const char *nombre, Clase clase, Tipo tipo, int ambito, int linea);
/* Busca sólo en un ámbito dado; -1 si no existe. */
int      ts_buscar_local(const char *nombre, int ambito);
/* Busca primero en el ámbito actual y después en el global; -1 si no es visible. */
int      ts_buscar(const char *nombre, int ambito);
Simbolo *ts_simbolo(int indice);
void     ts_agregar_parametro(int funcion, Tipo tipo);
void     ts_imprimir(void);

const char *tipo_nombre(Tipo tipo);
Tipo        tipo_de_letra(char letra);
char        letra_de_tipo(Tipo tipo);

void error_semantico(int linea, const char *formato, ...);

#endif

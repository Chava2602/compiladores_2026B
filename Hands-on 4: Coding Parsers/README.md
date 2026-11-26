# Hands-on 4: Coding Parsers

Parsers (Bison) y lexers (Flex) de `syntax-analizer/` en https://github.com/joseavinatecmm/compiladores,
compilados y ejecutados con bison 3.8.2, flex 2.6.4 y gcc 13 en Ubuntu 24.04 (WSL).

## Compilar y ejecutar

```bash
bison -d parser.y                     # gramática -> parser.tab.c + parser.tab.h (tokens)
flex lexer.l                          # lexer -> lex.yy.c (incluye parser.tab.h)
gcc -o parser parser.tab.c lex.yy.c   # un solo ejecutable
./parser prueba.c
```

Para compilar y ejecutar las cuatro versiones con todas sus pruebas: `bash run_all.sh`.

**Cómo se conectan las piezas:** `bison -d` genera `parser.tab.h` con los códigos de los tokens.
El lexer lo incluye y devuelve esos códigos desde `yylex()`. `yyparse()` llama a `yylex()` cada
vez que necesita el siguiente token y aplica la gramática LALR(1). Los caracteres sueltos
(`'('`, `';'`…) se devuelven tal cual, como su código ASCII.

## Análisis de cada versión

| Versión | Gramática | Prueba → resultado |
|---|---|---|
| **basic** | Solo `#include <lib.h>` seguido de `int main() { return 0; }`. Hasta el `0` es un token (`T_CERO`). | `prueba.c` → **ACCEPT** |
| **interm** | Agrega `#define` (con número o con expresión), funciones auxiliares `int f(int a, ...)`, declaraciones, asignaciones, llamadas y expresiones `+ - * /` con precedencia (`%left`). Hay una regla extra en la acción de `programa`: `main` debe llamar al menos a una función auxiliar (variable `llamada_en_main`). | `prueba.c` → **error de sintaxis**, porque a `calcular(...)` le falta el tipo `int` (línea 6). Sin recuperación, el análisis se detiene en el primer error. `prueba_ok.c` (con `int`) → **ACCEPT** |
| **advan** | Misma gramática, con `%option yylineno`, alias legibles para los tokens (`"tipo 'int'"`) y **producciones de error específicas**: función sin tipo, función sin nombre, `main` sin `int`, parámetro sin `int`, `return;` vacío, `#include` sin librería. También usa `error '}'` y `error ';'` con `yyerrok` para seguir analizando. | `prueba.c` → **ACCEPT**. Bison avisa que `%error-verbose` es una directiva obsoleta; hoy se escribe `%define parse.error verbose`. |
| **advance** | Diseño más limpio: `%locations` con renglón **y columna** (`YY_USER_ACTION`), condición de arranque `DIRECTIVA` para que `#define` termine en el salto de línea (token `FIN_DIRECTIVA`) y recuperación con `error` + `yyerrok` en directivas, parámetros y sentencias, cada una con su sugerencia. | `prueba.c` tiene 3 errores a propósito y **se reportan los 3** sin detenerse: `#define` sin nombre (1:10), parámetro sin nombre (3:18) y `return` sin `;` (7:1). `prueba_ok.c` → **Sintaxis correcta** |

**Conclusión:** la progresión muestra cómo crece un analizador sintáctico. Primero se valida una
estructura fija (basic). Luego se amplía la gramática con expresiones y precedencia (interm),
se agregan mensajes de error específicos (advan) y al final se recupera de los errores con
ubicación precisa para reportarlos todos en una sola pasada (advance). Esa última base es la que
extiende el proyecto final SlimC con análisis semántico.

`prueba_ok.c` (en `interm` y `advance`) es la versión corregida de cada `prueba.c`, agregada para
mostrar también el caso aceptado.

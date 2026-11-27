# Hands-on 5: SlimC Compiler

Front-end ligero (análisis léxico, sintáctico y semántico) para un subconjunto de C, hecho con
**Flex** y **Bison**. Extiende el analizador `semantic-analysis/advance` que se vio en clase.

## Archivos

| Archivo | Contenido |
|---|---|
| `lexer.l` | Especificación léxica (Flex) |
| `parser.y` | Gramática, recuperación de errores y acciones semánticas (Bison) |
| `tabla_simbolos.h` / `tabla_simbolos.c` | Tabla de símbolos, contadores de errores e impresión |
| `correcto.c` | Caso válido de la sección 8 → `ACCEPT` |
| `errores.c` | Caso de la sección 9, más una función `extra()` con errores léxicos, sintácticos y de retorno |
| `prueba_extra.c` | Prueba adicional: varios `#include`, `#define PI 3.14`, `const double`, comentarios multilínea, `!`, `&&` |
| `Makefile` | `make`, `make test`, `make clean` |

## Compilar y ejecutar (Linux / WSL)

```bash
sudo apt install flex bison gcc make   # una sola vez
make                                   # bison -d parser.y && flex lexer.l && gcc ...
./slimc correcto.c
./slimc errores.c
```

El programa termina con código `0` si el archivo se acepta y con `1` si hay errores.

## Qué se agregó

### Léxico (`lexer.l`)
- Operadores relacionales `== != < > <= >=` y lógicos `&& || !`.
- Comentarios `//` y `/* ... */`. El de varias líneas usa la condición de arranque `COMENTARIO`.
  Como flex lleva la cuenta de cada `\n` con `%option yylineno`, los números de línea no se
  desfasan. Si un `/*` llega al fin de archivo sin cerrarse, se reporta como error léxico.
- `#include <lib.h>` y `#include "lib.h"` (el nombre de la librería se guarda en la tabla),
  `#define`, `const`, `if`, `else` y `while`.
- Errores léxicos con número de línea: carácter no válido, cadena sin cerrar, identificador mal
  formado (`2abc`), directiva desconocida y comentario sin cerrar.

### Sintáctico (`parser.y`)
- Los `#include`, `#define` y `const` pueden mezclarse libremente al inicio, junto con las
  funciones y `main`.
- `if`, `if-else` y `while` con bloques `{ }`. No hay ambigüedad de *dangling else* porque los
  bloques llevan llaves obligatorias, y Bison no reporta conflictos.
- `return` puede aparecer en cualquier sentencia. Las llamadas pueden usarse como sentencia.
- **Recuperación de errores** con `error ';' { yyerrok; }` a nivel de sentencia y
  `error ';'` / `error '}'` a nivel global. Así se reportan varios errores en una sola corrida.
- Mensajes de Bison (`parse.error verbose`) traducidos al español, con número de línea.

### Semántico
| Verificación | Mensaje |
|---|---|
| Macro redefinida | `macro 'LIMITE' ya definida.` |
| Asignar a `const` / `#define` | `no se puede asignar un valor a la constante 'BASE'.` / `... a la macro 'X'.` |
| Aridad | `la función 'calcular' espera 2 argumento(s), pero recibió 1.` |
| Variable no visible | `variable 'a' no declarada en el ámbito actual.` |
| Variable en condición | `variable 'x' no declarada en condición 'if'` (o `'while'`) |
| Tipo de argumento | `tipo incompatible en argumento 1 de 'calcular' (se esperaba 'int', se recibió 'double').` |
| Asignación / inicialización | `tipo incompatible al inicializar 'm' (se esperaba 'int', se recibió 'double').` |
| Tipo de retorno | `tipo de retorno incompatible en 'f' (se esperaba 'int', se recibió 'double').` |
| Redeclaración en el mismo ámbito | `el símbolo 'x' ya está declarado en el ámbito 'main' (línea N).` |
| Función/variable mal usada | `'f' es una función y se usó como variable.`, `'x' no es una función.` |
| `%` con double, falta de `main` | también se reportan |

**Regla de tipos:** se permite `int → double` (promoción), pero no `double → int`. Las
expresiones relacionales y lógicas dan `int`. Un operando erróneo se propaga como tipo `?`
(`T_ERROR`) para no repetir el mismo error en cascada.

**Ámbitos:** global (`-1`) o el índice de la función dueña. Las variables que se declaran dentro
de un bloque `if`/`while` pertenecen al ámbito de la función (simplificación de SlimC).

Al final se imprime la **tabla de símbolos** (Nombre, Clase, Tipo, Ámbito, Aridad, Const, Línea),
el conteo de errores léxicos, sintácticos y semánticos, y `ACCEPT` o `REJECT`.

## Salida de `errores.c`

```
Error semántico en línea 3: macro 'LIMITE' ya definida.
Error semántico en línea 22: no se puede asignar un valor a la constante 'BASE'.
Error semántico en línea 23: la función 'calcular' espera 2 argumento(s), pero recibió 1.
Error semántico en línea 24: variable 'a' no declarada en el ámbito actual.
Error semántico en línea 25: tipo incompatible en argumento 1 de 'calcular' (se esperaba 'int', se recibió 'double').
Error semántico en línea 27: variable 'noDeclarada' no declarada en condición 'if'.
Error semántico en línea 31: variable 'contador' no declarada en condición 'while'.
Error léxico en línea 41: carácter no válido '@'.
Error sintáctico en línea 42: no se esperaba ';'.
Error sintáctico en línea 43: no se esperaba '='.
Error semántico en línea 44: no se puede asignar un valor a la macro 'LIMITE'.
Error semántico en línea 48: tipo de retorno incompatible en 'extra' (se esperaba 'int', se recibió 'double').
...
Errores léxicos:     1
Errores sintácticos: 2
Errores semánticos:  9
Resultado: REJECT
```

Las primeras 7 líneas coinciden exactamente con los errores esperados en la sección 9 de la actividad.

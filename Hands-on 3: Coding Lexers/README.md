# Hands-on 3: Coding Lexers

Lexers tomados de `lexical-analyzer/` en https://github.com/joseavinatecmm/compiladores.
Entrada de prueba: `test.c`. Herramientas: flex 2.6.4 y gcc 13 en Ubuntu 24.04 (WSL).

## Compilar y ejecutar

Cada lexer se compila igual:

```bash
flex -o lex.yy.c analizador-ver3.l     # .l  ->  código C del autómata
gcc lex.yy.c -o lexer                  # C   ->  ejecutable
./lexer < test.c                       # ver1, ver2, ver3, ver4, ver-11 leen stdin
./lexer test.c                         # ver-12 recibe el archivo como argumento
```

Para compilar y ejecutar los seis lexers en una sola corrida: `bash run_all.sh`.

## Análisis

Cada archivo `.l` tiene tres secciones separadas por `%%`: **definiciones** (código C entre `%{ %}` y
alias de expresiones regulares), **reglas** (patrón → acción) y **código de usuario** (`main`).
flex resuelve las ambigüedades con dos criterios:
1. **Coincidencia más larga.** Por eso `++` gana sobre `+` y `>=` gana sobre `>`.
2. **Ante empate de longitud, gana la regla que aparece primero.** Por eso las palabras reservadas
   se declaran antes que `IDENTIFICADOR`: `int` cumple ambos patrones con la misma longitud.

| Versión | Qué añade | Lo que se observa con `test.c` |
|---|---|---|
| **ver1** | Solo `ENTERO [0-9]+`. Ignora los espacios y marca todo lo demás con `.` como DESCONOCIDA. | Solo `0`, `5`, `10` y `1` salen como INTEGER. Las palabras salen letra por letra (`i`,`n`,`t`), porque ningún patrón las agrupa. |
| **ver2** | Palabras reservadas, `IDENTIFICADOR [A-Za-z_][A-Za-z0-9_]*` y enteros. | `int`, `for`, `if` y `return` salen como reservadas; `main` y `total` como identificadores. Los operadores y la puntuación salen como "no reconocido". |
| **ver3** | Operadores (incremento, asignación, comparación, lógicos y aritméticos) y delimitadores `() {} [] ; ,`. | Se reconocen todos los tokens del código. `++`, `+=` y `>=` salen como un solo token por la coincidencia más larga. **Limitación:** el comentario `//` sale como dos operadores `/` y su texto como identificadores. |
| **ver4** | Se reorganiza con **definiciones con nombre** (`{COMPARACION}`, `{LOGICO}`…) y se agrega `DECIMAL {ENTERO}"."{ENTERO}`. | `3.14` sale como DECIMAL aunque su regla esté después de ENTERO, por la coincidencia más larga. Es una versión **reducida a propósito o incompleta**: faltan `for`, `while` y `return` en las reservadas (salen como IDENTIFICADOR); no hay reglas para `)`, `}` y `]`; no se usa la definición `ASIGNACION`, a la que además le falta el `)` (flex no da error porque nunca se expande); `=` no se reconoce; `+=` se parte en `+` y `=`; `!=` se parte en `!` y `=`. |
| **ver-11** | Cambio de diseño: la acción ya no imprime, sino que llena un `struct Token` y hace `return 1`. Es `main` quien llama a `yylex()` en un ciclo **token por token**, como lo haría un parser. | La clasificación es como en ver2, pero sin `void` ni `while` en las reservadas (`void` sale como IDENTIFICADOR). Lo que no es palabra ni número sale como NO_RECONOCIDO. |
| **ver-12** | Lee el archivo desde `argv[1]` con `yyin` y maneja los errores de `fopen`/`fclose`. Agrupa en OPERADOR y DELIMITADOR. **Descarta los comentarios `//`**. Agrega `noinput nounput` para evitar advertencias de gcc. Imprime en columnas alineadas con `%-18s`. | Es la salida más limpia: el comentario desaparece. **Detalle:** la definición `SALTO` existe pero no tiene regla, así que cada `\n` cae en la regla por defecto de flex (ECHO) y se imprime una línea en blanco. Además, si `test.c` tiene finales de línea CRLF (por ejemplo, si se clonó desde Windows), cada `\r` sale como NO_RECONOCIDO. Se corrige agregando la regla `{SALTO} { }`. |

**Conclusión:** las versiones muestran cómo crece un analizador léxico. Primero se agregan clases de
tokens (ver1 → ver3), luego se organiza con definiciones (ver4), después se separa el reconocimiento
de la impresión para integrarlo con un parser (ver-11) y al final queda una herramienta usable sobre
archivos (ver-12).

## Guion para el video (2 a 4 minutos)

Grábalo en la terminal de Ubuntu (WSL) con el prompt visible (`usuario@equipo`). Sirven la
Grabación de pantalla del Recortes de Windows (Win+Shift+R), la Xbox Game Bar (Win+G) u OBS.

1. `whoami; hostname; date`: muestra tu usuario.
2. `git clone https://github.com/joseavinatecmm/compiladores && cd compiladores/lexical-analyzer`.
   Clonar dentro de Linux evita el problema de CRLF.
3. `ls` y `cat test.c`.
4. Por cada versión: `cat analizador-verN.l` (explica qué agrega), luego `flex …`, `gcc …` y ejecuta.
   Si quieres hacerlo rápido, copia `run_all.sh` y corre `bash run_all.sh`.
5. Comenta lo que se observa: las letras sueltas en ver1, la coincidencia más larga en ver3, lo que
   le falta a ver4 y los comentarios descartados en ver-12.
6. Sube el video a YouTube como **No listado** (o a Google Drive con "Cualquier persona con el
   enlace") y entrega el enlace en Classroom.

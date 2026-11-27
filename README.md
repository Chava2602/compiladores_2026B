# Compiladores 2026B — Hands-on

Prácticas de la materia **Compiladores**, CUCEI, Universidad de Guadalajara.
Profesor: José Antonio Aviña Méndez.

Este repositorio reúne los cinco *Hands-on* del curso. Juntos recorren las tres primeras fases de un
compilador: **análisis léxico, sintáctico y semántico**. Se parte de un autómata escrito a mano en
C++ y se termina con un *front-end* completo para un subconjunto de C hecho con Flex y Bison.

```
código fuente ──► Análisis léxico ──► Análisis sintáctico ──► Análisis semántico
                  Hands-on 1, 2, 3     Hands-on 4              Hands-on 5 (SlimC)
                  tokens               gramática / parser      tabla de símbolos, tipos
```

## Índice

| # | Práctica | Tema | Herramientas |
|---|---|---|---|
| 1 | [Análisis Léxico y Autómatas](#hands-on-1-análisis-léxico-y-autómatas) | AFD + máquina de Moore para instrucciones tipo ensamblador | C++ |
| 2 | [Flex setting-up](#hands-on-2-flex-setting-up) | Instalación y verificación del entorno | Flex, GCC |
| 3 | [Coding Lexers](#hands-on-3-coding-lexers) | 6 versiones de un analizador léxico | Flex, GCC |
| 4 | [Coding Parsers](#hands-on-4-coding-parsers) | 4 versiones de un analizador sintáctico | Bison, Flex |
| 5 | [SlimC Compiler](#hands-on-5-slimc-compiler-actividad-integradora) | Léxico + sintáctico + semántico para un subconjunto de C | Bison, Flex |

## Entorno

Windows 11 con **WSL** (Ubuntu 24.04 LTS).

```bash
sudo apt update
sudo apt install -y flex bison gcc g++ make
```

| Herramienta | Versión |
|---|---|
| flex | 2.6.4 |
| bison | 3.8.2 |
| gcc / g++ | 13.3.0 |
| GNU Make | 4.3 |

---

## Hands-on 1: Análisis Léxico y Autómatas

📁 [`Hands-on 1: Análisis Léxico y Autómatas/`](<Hands-on 1: Análisis Léxico y Autómatas>)

**Objetivo:** construir a mano, sin generadores, un analizador léxico basado en un **autómata finito
determinista (AFD)** que valide instrucciones de un lenguaje tipo ensamblador. Con la instrucción ya
reconocida, una **máquina de Moore** genera las microoperaciones que ejecutaría el procesador.

| Archivo | Contenido |
|---|---|
| `afd_parser.cpp` | AFD (`enum class EstadoAFD`), tokens, objeto instrucción y máquina de Moore (`enum class EstadoMoore`) |

**Lenguaje reconocido:**

| Instrucción | Forma | Significado |
|---|---|---|
| `MOV` | `MOV AL, 100` | carga en el registro el contenido de la dirección (direccionamiento directo) |
| `ADD` | `ADD AL, BL` | suma dos registros en el acumulador |
| `STO` | `STO 25` | guarda el acumulador en memoria |

Los registros válidos son `AL` y `BL`. Las direcciones son enteros.

**Cómo funciona:**
1. `validarAFD()` recorre la entrada carácter por carácter. Cada letra del mnemónico es un estado
   (`M → MO → MOV`, `A → AD → ADD`, `S → ST → STO`). Después siguen los estados `ESPACIO`,
   `REGISTRO`, `REGISTRO_A/B`, `REGISTRO_COMPLETO` y `NUMERO`. Cualquier carácter inesperado lleva
   al estado `ERROR`.
2. En cada transición aceptada se emite un token (`MOV`, `REGISTRO`, `COMA`, `NUMERO`) y se llena un
   objeto `Instruccion` con la operación, los registros y la dirección.
3. `ejecutarMoore()` recorre los estados de Moore. Cada estado produce una salida, que es una
   microoperación del ciclo máquina (MAR, MBR, memoria, ACC).

**Compilar y ejecutar:**

```bash
cd "Hands-on 1: Análisis Léxico y Autómatas"
g++ -o afd_parser afd_parser.cpp
./afd_parser            # escribir la instrucción, p. ej.: MOV AL, 100
```

**Resultados:**

```
Ingrese una instruccion: MOV AL, 100        Ingrese una instruccion: STO 25
Instruccion valida.                         Instruccion valida.
TOKENS RECONOCIDOS                          TOKENS RECONOCIDOS
MOV("MOV")                                  STO("STO")
REGISTRO("AL")                              NUMERO("25")
COMA(",")
NUMERO("100")                               MICROOPERACIONES GENERADAS POR MOORE
                                            1. MAR <- 25
MICROOPERACIONES GENERADAS POR MOORE        2. MBR <- ACC
1. MAR <- 100                               3. M[MAR] <- MBR
2. MBR <- M[MAR]
3. AL <- MBR
```

`ADD AL, BL` genera `ACC <- AL + BL`.

**Observaciones:** el ciclo de `validarAFD()` termina en cuanto se consume el último carácter. Por
eso no llega a ejecutar la acción del último estado alcanzado, lo que tiene dos efectos:
- `END` se rechaza, porque nunca se procesa el estado `END`.
- En `ADD AL, BL` el segundo registro (`BL`) no se agrega a la lista de tokens.

Se corrige procesando el estado final después del ciclo, como ya se hace para `ADD`.

---

## Hands-on 2: Flex setting-up

📁 [`Hands-on 2: Flex setting-up/`](<Hands-on 2: Flex setting-up>)

**Objetivo:** instalar y verificar el entorno con el que se compilan los lexers (Flex) y los
parsers (Bison) del resto del curso.

| Archivo | Contenido |
|---|---|
| `verificar.sh` | muestra las versiones de flex, bison, gcc y make, y compila el lexer de prueba |
| `contador.l` | lexer mínimo: cuenta líneas, palabras, números y caracteres |
| `entrada.txt` | texto de prueba |

**Flujo de trabajo con Flex:**

```
contador.l ──flex──► lex.yy.c ──gcc──► contador
```

Un archivo `.l` tiene tres secciones separadas por `%%`:
1. **definiciones** (`%option`, código C entre `%{ %}` y alias de expresiones regulares);
2. **reglas** (`patrón { acción }`);
3. **código de usuario** (`main`, que llama a `yylex()`).

**Ejecutar:**

```bash
cd "Hands-on 2: Flex setting-up" && bash verificar.sh
```

```
flex   -> flex 2.6.4
bison  -> bison (GNU Bison) 3.8.2
gcc    -> gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
make   -> GNU Make 4.3

$ ./contador entrada.txt
Lineas: 3 | Palabras: 19 | Numeros: 3 | Caracteres (bytes): 117
```

---

## Hands-on 3: Coding Lexers

📁 [`Hands-on 3: Coding Lexers/`](<Hands-on 3: Coding Lexers>)

**Objetivo:** analizar, compilar y ejecutar los lexers revisados en clase, y grabar un video de
evidencia desde la terminal.

| Archivo | Contenido |
|---|---|
| `analizador-ver1.l` … `analizador-ver-12.l` | las 6 versiones del lexer |
| `test.c` | programa C de prueba |
| `run_all.sh` | compila y ejecuta las 6 versiones |
| `HandsOn3_CodingLexers.mp4` | video de evidencia (compilación y ejecución en WSL) |
| `grabar_demo.sh`, `grabar.ps1` | scripts con los que se grabó el video |
| `README.md` | análisis detallado de cada versión |

**Reglas de flex que explican los resultados:**
1. **Coincidencia más larga:** `++` gana sobre `+` y `>=` gana sobre `>`.
2. **En empate de longitud gana la regla que va primero:** por eso las palabras reservadas se
   declaran antes que `IDENTIFICADOR` (`int` cumple ambos patrones).

**Evolución de las versiones:**

| Versión | Qué agrega | Resultado con `test.c` |
|---|---|---|
| ver1 | solo `ENTERO [0-9]+` | las palabras salen letra por letra como DESCONOCIDA |
| ver2 | palabras reservadas e identificadores | operadores y puntuación salen como "no reconocido" |
| ver3 | operadores (asignación, comparación, lógicos, aritméticos) y delimitadores | reconoce todo el código; `//` sale como dos `/` |
| ver4 | definiciones con nombre y `DECIMAL` | versión incompleta: faltan `)`, `}`, `=` y `for`/`return` como reservadas |
| ver-11 | `yylex()` devuelve un token (`struct Token`) y `main` lo consume en un ciclo | mismo diseño que usa un parser |
| ver-12 | lee el archivo de `argv[1]`, descarta comentarios, salida en columnas | la más limpia; `SALTO` no tiene regla, así que cada `\n` imprime una línea en blanco |

**Compilar y ejecutar:**

```bash
cd "Hands-on 3: Coding Lexers"
flex -o lex.yy.c analizador-ver3.l && gcc lex.yy.c -o lexer && ./lexer < test.c
bash run_all.sh        # las 6 versiones
```

```
Clase: PALABRA_RESERVADA | Lexema: for
Clase: PARENTESIS_IZQUIERDO | Lexema: (
Clase: IDENTIFICADOR | Lexema: i | Longitud: 1
Clase: OPERADOR_COMPARACION | Lexema: <
Clase: INCREMENTO_DECREMENTO | Lexema: ++
Clase: OPERADOR_ASIGNACION | Lexema: +=
```

---

## Hands-on 4: Coding Parsers

📁 [`Hands-on 4: Coding Parsers/`](<Hands-on 4: Coding Parsers>)

**Objetivo:** analizar, compilar y ejecutar los parsers (Bison) y sus lexers (Flex) revisados en clase.

| Carpeta | Archivos |
|---|---|
| `basic/`, `interm/`, `advan/`, `advance/` | `lexer.l`, `parser.y`, `prueba.c` (más `prueba_ok.c` en `interm` y `advance`) |
| `run_all.sh` | compila y ejecuta las 4 versiones con todas sus pruebas |
| `README.md` | análisis detallado |

**Cómo se conectan Flex y Bison:**

```
parser.y ──bison -d──► parser.tab.c + parser.tab.h (códigos de tokens)
lexer.l  ──flex─────► lex.yy.c   (incluye parser.tab.h)
gcc parser.tab.c lex.yy.c ──► parser
```

`yyparse()` llama a `yylex()` cada vez que necesita el siguiente token y aplica la gramática LALR(1).

**Evolución de las versiones:**

| Versión | Gramática | Resultado |
|---|---|---|
| basic | estructura fija: `#include <lib.h>` + `int main() { return 0; }` | `prueba.c` → **ACCEPT** |
| interm | `#define`, funciones con parámetros, declaraciones, llamadas y expresiones con precedencia (`%left`) | `prueba.c` → **error**: a `calcular` le falta `int`, y sin recuperación el análisis se detiene. `prueba_ok.c` → **ACCEPT** |
| advan | alias legibles de tokens, `yylineno` y producciones de error específicas (función sin tipo, `main` sin `int`, `return;` vacío…) | `prueba.c` → **ACCEPT** |
| advance | `%locations` (renglón y columna), condición de arranque para `#define` y recuperación con `error` + `yyerrok` | `prueba.c` → **los 3 errores** reportados en una sola pasada. `prueba_ok.c` → **Sintaxis correcta** |

**Compilar y ejecutar:**

```bash
cd "Hands-on 4: Coding Parsers/advance"
bison -d parser.y && flex lexerl.l && gcc -o parser parser.tab.c lex.yy.c
./parser prueba.c
```

```
Error sintactico en renglon 1, columna 10.
  Se esperaba: #define NOMBRE ENTERO
Error sintactico en renglon 3, columna 18.
  Parametros incorrectos. Ejemplo: (int a, int b)
Error sintactico en renglon 7, columna 1.
  Se esperaba una expresion valida despues de return.
```

---

## Hands-on 5: SlimC Compiler (actividad integradora)

📁 [`SlimC Compiler/`](<SlimC Compiler>)

**Objetivo:** extender el analizador semántico visto en clase hasta obtener el *front-end* completo
(léxico, sintáctico y semántico) de **SlimC**, un subconjunto de C.

| Archivo | Contenido |
|---|---|
| `lexer.l` | especificación léxica (Flex) |
| `parser.y` | gramática, recuperación de errores y acciones semánticas (Bison) |
| `tabla_simbolos.h` / `.c` | tabla de símbolos, contadores de errores e impresión final |
| `correcto.c` | caso válido → `ACCEPT` |
| `errores.c` | caso con errores léxicos, sintácticos y semánticos |
| `prueba_extra.c` | prueba adicional (varios `#include`, `#define PI 3.14`, `const double`, comentarios) |
| `Makefile` | `make`, `make test`, `make clean` |

**Qué hace cada fase:**

- **Léxico:** directivas `#include` y `#define`, `const`, tipos `int`/`double`, `if`/`else`/`while`,
  operadores relacionales (`== != < > <= >=`) y lógicos (`&& || !`), comentarios `//` y `/* */` sin
  desfasar `yylineno`, y errores léxicos con número de línea.
- **Sintáctico:** directivas, macros y constantes en cualquier orden; funciones tipadas con
  parámetros; `if`, `if-else` y `while` con bloques; **recuperación de errores** con
  `error ';' { yyerrok; }` para reportar varios errores en una sola ejecución.
- **Semántico:** cada símbolo de la tabla guarda nombre, clase, tipo, ámbito, aridad, si es
  constante y línea. Se verifica:
  - ámbito y declaración de variables, incluidas las que aparecen en condiciones `if`/`while`;
  - aridad y tipos de los argumentos;
  - compatibilidad `int`/`double` (se permite `int → double`, pero no al revés);
  - que no se asigne a `const` ni a `#define`, que no se redefinan macros ni se redeclaren símbolos;
  - el tipo del valor de `return`.

**Compilar y ejecutar:**

```bash
cd "SlimC Compiler"
make
./slimc correcto.c
./slimc errores.c
```

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

================================ TABLA DE SIMBOLOS ================================
#   Nombre         Clase      Tipo    Ambito     Aridad  Const  Linea
-----------------------------------------------------------------------------------
1   LIMITE         macro      int     global     -       si     2
2   BASE           constante  int     global     -       si     5
3   calcular       funcion    int     global     2       no     7
4   a              parametro  int     calcular   -       no     7
...
Errores léxicos:     1
Errores sintácticos: 2
Errores semánticos:  9
Resultado: REJECT
```

Con `correcto.c` el resultado es `Resultado: ACCEPT`, con 0 errores.

---

## Créditos

El código base de los Hands-on 3, 4 y 5 proviene del repositorio del curso:
https://github.com/joseavinatecmm/compiladores

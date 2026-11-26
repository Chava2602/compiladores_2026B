# Hands-on 2: Análisis Léxico con Flex — *Flex setting-up*

Instalación y verificación del entorno con el que se compilan los lexers (Flex) y, más adelante,
los parsers (Bison).

## Entorno

Windows 11 + **WSL** con **Ubuntu 24.04 LTS**.

```bash
# En PowerShell (una sola vez): instalar WSL con Ubuntu
wsl --install -d Ubuntu-24.04

# En Ubuntu
sudo apt update
sudo apt install -y flex bison gcc make
```

## Verificación

`verificar.sh` muestra las versiones instaladas y compila un lexer mínimo (`contador.l`) que cuenta
las líneas, palabras, números y caracteres de `entrada.txt`:

```bash
bash verificar.sh
```

Salida obtenida:

```
Sistema: Ubuntu 24.04.5 LTS

flex   -> flex 2.6.4
bison  -> bison (GNU Bison) 3.8.2
gcc    -> gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
make   -> GNU Make 4.3

$ flex contador.l
$ gcc lex.yy.c -o contador
$ ./contador entrada.txt
Lineas: 3 | Palabras: 19 | Numeros: 3 | Caracteres (bytes): 117
```

## Flujo de trabajo con Flex

```
contador.l  --flex-->  lex.yy.c  --gcc-->  contador (ejecutable)
```

Un archivo `.l` tiene tres secciones separadas por `%%`:
1. **Definiciones:** opciones (`%option noyywrap`), código C entre `%{ %}` y alias de expresiones regulares.
2. **Reglas:** `patrón  { acción en C }`. Flex elige la coincidencia más larga y, si hay empate, la
   regla que aparece primero.
3. **Código de usuario:** normalmente `main()`, que llama a `yylex()`.

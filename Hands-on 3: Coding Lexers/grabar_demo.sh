#!/usr/bin/env bash
# Demo automatizada para el video del Hands-on 3: escribe cada comando "a mano"
# y lo ejecuta de verdad en WSL. Uso: bash grabar_demo.sh [carpeta-con-los-.l]
DIR="${1:-$HOME/compiladores_26b/Hands-on 3: Coding Lexers/compiladores/lexical-analyzer}"
FLAG="${2:-/tmp/demo_done}"; rm -f "$FLAG"
cd "$DIR" || exit 1

G=$'\e[1;32m'; B=$'\e[1;34m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; R=$'\e[0m'
prompt() { printf '%s%s@%s%s:%s~/…/lexical-analyzer%s$ ' "$G" "$(whoami)" "$(hostname)" "$R" "$B" "$R"; }
teclear() { local s="$1" i; for ((i=0;i<${#s};i++)); do printf '%s' "${s:i:1}"; sleep 0.035; done; sleep 0.3; echo; }
cmd() { prompt; teclear "$1"; eval "$1"; sleep "${2:-1.2}"; }
titulo() { echo; printf '%s# ===== %s =====%s\n' "$Y" "$1" "$R"; sleep 1.2; }
nota() { printf '%s# %s%s\n' "$C" "$1" "$R"; sleep 2.2; }

clear; sleep 2
titulo "Hands-on 3: Coding Lexers — flex + gcc en WSL"
cmd "whoami"
cmd "hostname"
cmd "date"
cmd "pwd"
cmd "flex --version && gcc --version | head -1"
cmd "ls *.l test.c" 2

titulo "Programa de prueba (test.c)"
cmd "cat test.c" 4

lexer() { # $1 versión, $2 entrada, $3 nota
    clear
    titulo "analizador-$1.l"
    nota "$3"
    cmd "flex -o lex-$1.c analizador-$1.l"
    cmd "gcc -o $1 lex-$1.c"
    cmd "echo \"$2\" | ./$1" 4.5
}

lexer ver1   "123 45 abc 7" \
  "Solo reconoce ENTEROS [0-9]+; el resto se marca como DESCONOCIDA, caracter por caracter."
lexer ver2   "int x = 42; return x;" \
  "Agrega palabras reservadas e IDENTIFICADOR; las reservadas van primero (empate de longitud)."
lexer ver3   "if (a >= 10 && b != 0) { a += 1; i++; }" \
  "Agrega operadores y delimitadores; regla de coincidencia más larga: >=, +=, ++ son un solo token."
lexer ver4   "float pi = 3.14; x++; if (a > b)" \
  "Usa definiciones con nombre y agrega DECIMAL; faltan reglas para '=' y ')'."
lexer ver-11 "int total 25 #" \
  "yylex() devuelve un token (struct Token) y main lo consume en un ciclo, como un parser."

clear
titulo "analizador-ver-12.l"
nota "Lee un archivo desde argv[1] (yyin) y descarta los comentarios //."
cmd "flex -o lex-ver-12.c analizador-ver-12.l"
cmd "gcc -o ver-12 lex-ver-12.c"
cmd "./ver-12 test.c" 6

echo
printf '%s# Fin de la demostración — %s@%s%s\n' "$Y" "$(whoami)" "$(hostname)" "$R"
[ -n "$FLAG" ] && touch "$FLAG"
sleep 600

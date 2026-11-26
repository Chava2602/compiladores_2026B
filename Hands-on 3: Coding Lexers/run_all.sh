#!/usr/bin/env bash
# Hands-on 3: Coding Lexers — compila y ejecuta todos los lexers con flex + gcc.
# Uso:  bash run_all.sh
cd "$(dirname "$0")"

echo "Usuario: $(whoami)@$(hostname)   Fecha: $(date)"
echo "flex: $(flex --version)   gcc: $(gcc -dumpversion)"

for v in ver1 ver2 ver3 ver4 ver-11 ver-12; do
    echo
    echo "=================== analizador-$v.l ==================="
    echo "\$ flex -o lex_$v.yy.c analizador-$v.l"
    flex -o "lex_$v.yy.c" "analizador-$v.l" || { echo "ERROR en flex"; continue; }
    echo "\$ gcc lex_$v.yy.c -o lexer_$v"
    gcc "lex_$v.yy.c" -o "lexer_$v" || { echo "ERROR en gcc"; continue; }

    if [ "$v" = "ver-12" ]; then
        echo "\$ ./lexer_$v test.c"
        "./lexer_$v" test.c
    else
        echo "\$ ./lexer_$v < test.c"
        "./lexer_$v" < test.c
    fi
done

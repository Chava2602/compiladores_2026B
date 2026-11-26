#!/usr/bin/env bash
# Hands-on 4: Coding Parsers — compila (bison + flex + gcc) y ejecuta cada parser con sus pruebas.
# Uso: bash run_all.sh
cd "$(dirname "$0")"
echo "Usuario: $(whoami)@$(hostname)   $(date)"
echo "$(bison --version | head -1) | $(flex --version) | gcc $(gcc -dumpversion)"

for d in basic interm advan advance; do
    echo
    echo "==================== $d ===================="
    (
        cd "$d" || exit
        lex=$(ls *.l)
        echo "\$ bison -d parser.y";                   bison -d parser.y
        echo "\$ flex $lex";                           flex "$lex"
        echo "\$ gcc -o parser parser.tab.c lex.yy.c"; gcc -o parser parser.tab.c lex.yy.c
        for p in prueba*.c; do
            echo
            echo "\$ cat $p";  cat -n "$p"
            echo "\$ ./parser $p"
            stdbuf -oL -eL ./parser "$p" 2>&1
            echo "(código de salida: $?)"
        done
    )
done

#!/usr/bin/env bash
# Hands-on 2: verifica la instalación de Flex/GCC/Bison y compila un lexer de prueba.
# Uso: bash verificar.sh
cd "$(dirname "$0")"
echo "Usuario: $(whoami)@$(hostname)   $(date)"
echo "Sistema: $(. /etc/os-release && echo "$PRETTY_NAME")"
echo
for herramienta in flex bison gcc make; do
    printf '%-6s -> ' "$herramienta"
    if command -v "$herramienta" >/dev/null; then
        "$herramienta" --version | head -1
    else
        echo "NO INSTALADO (sudo apt install $herramienta)"
    fi
done
echo
echo '$ flex contador.l';           flex contador.l
echo '$ gcc lex.yy.c -o contador';  gcc lex.yy.c -o contador
echo '$ ./contador entrada.txt';    ./contador entrada.txt

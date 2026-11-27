#include <stdio.h>
#define LIMITE 10
#define LIMITE 20

const int BASE = 5;

int calcular(int a, int b) {
    int suma = a + b;
    return suma;
}

double promedio(int a, int b) {
    return calcular(a, b) / 2.0;
}

int main() {
    int x = 4;
    int total = calcular(x, 5);
    double media = promedio(x, BASE);
    printf("total = %d, media = %.1f\n", total, media);

    BASE = 8;
    int falta = calcular(x);
    int invisible = a;
    int incompatible = calcular(2.5, 5);

    if (noDeclarada > 0) {
        x = 1;
    }

    while (contador < 5) {
        x = x + 1;
    }

    return 0;
}

/* Casos adicionales: errores lexicos, sintacticos y de retorno.
   El analizador debe reportarlos todos sin detenerse. */
int extra(int n) {
    int y = n * 2; @
    int z = (n + ;
    y = = 3;
    LIMITE = 3;
    if (y >= 1 && n != 0) {
        y = y - 1;
    }
    return 2.5;
}

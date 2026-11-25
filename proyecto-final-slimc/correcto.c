#include <stdio.h>
#define LIMITE 10

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
    int total = calcular(x, BASE);
    double media = promedio(x, BASE);

    if (total > LIMITE) {
        printf("total alto = %d\n", total);
    } else {
        printf("total = %d, media = %.1f\n", total, media);
    }

    while (x < BASE) {
        x = x + 1;
    }

    return 0;
}

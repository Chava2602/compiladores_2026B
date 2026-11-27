#include <stdio.h>
#include <stdlib.h>
#define MAX 10
#define PI 3.14
const int BASE = 5;
const double FACTOR = 2.0;

/* comentario
   de varias
   lineas */
double area(double r) {
    return PI * r * r;   // comentario de una linea
}

int main() {
    int i = 0;
    double s = 0;
    if (i == 0) {
        s = area(FACTOR);
    }
    while (i < MAX && !(i >= BASE)) {
        i = i + 1;
    }
    int malo = s;
    PI = 3;
    return i;
}

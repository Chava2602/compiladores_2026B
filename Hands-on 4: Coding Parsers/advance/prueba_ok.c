#define MAX 5

int calcular(int a, int b) {
    int producto = b * 2;
    int resultado = a + producto;
    return resultado;
}

int main() {
    int x = 4;
    int res = calcular(x, MAX);
    return 0;
}

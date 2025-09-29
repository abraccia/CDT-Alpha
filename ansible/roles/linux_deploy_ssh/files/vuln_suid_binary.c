#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// MTAwIG1lYXN1cmVzIG9mIG9pbA==
int main(int argc, char *argv[]) {
    char barrelsofoil[100] = "/bin/cat ";
    if (argc < 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }
    strncat(barrelsofoil, argv[1], 90);
    system(barrelsofoil);
    return 0;
}
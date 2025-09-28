#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {
    char cmd[100] = "/bin/cat ";
    if (argc < 2) {
        printf("Usage: %s <filename>\n", argv[0]);
        return 1;
    }
    strncat(cmd, argv[1], 90);
    system(cmd);
    return 0;
}
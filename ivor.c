#include <stdlib.h>
#include <stdio.h>
#include <string.h>

char* readCmd(char* cmd) {
    FILE *process = popen(cmd, "r");
    int max = 4096;
    char* result = malloc(max + 1);
    fread(result, max, 1, process);
    pclose(process);
    return result;
}

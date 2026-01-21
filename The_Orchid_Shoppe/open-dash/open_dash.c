#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
// Attempts to open launch.env If the file doesn’t exist silently continue using defaults
static void load_env_file(const char* filename) {   //
    FILE* f = fopen(filename, "r");                 // 
    if (!f) return;                                 //   
    char line[256]; // Buffer to hold one line from the file, limited to 256
    while (fgets(line, sizeof(line), f)) {  // Reads the file line by line (e.g. DASH_URL=HTTP://0.0.0.0:0000/)
        char key[128], value[128];          // 256 is split, key = DASH_URL and value = HTTP://0.0.0.0:0000/
        if (sscan(line, "%127[^=]=%127[^\n]", key, value) == 2) {
            _putenv_s(key, value);
        }
    }
    fclose(f);
}

static const char* env_or(const char* k, const char* fallback) {
    const char* v = getenv(k); // Standard C function, searches system's environment list for sting matches `k`
    return (v && v[0]) ? v : fallback; // condition ? result_if_true : result_if_fasle
}
// Continue not done.

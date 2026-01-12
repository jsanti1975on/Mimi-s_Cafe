# Add Cyber-Range Dashboard launcher here
- Remider to explain what was added below in the c block
```C
static void load_env_file(const char* filename) {
    FILE* f = fopen(filename, "r");
    if (!f) return;
    char line[256];
    while (fgets(line, sizeof(line), f)) {
        char key[128], value[128];
        if (sscanf(line, "%127[^=]=%127[^\n]", key, value) == 2) {
            _putenv_s(key, value);
        }
    }
    fclose(f);
}
```
 

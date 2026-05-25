#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

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

static const char* env_or(const char* k, const char* fallback) {
    const char* v = getenv(k);
    return (v && v[0]) ? v : fallback;
}

static int do_ping(const char* host, const char* count) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -n %s %s >NUL 2>&1", count, host);
    return system(cmd);
}

int main() {
    load_env_file("launch.env");   // <-- Add this line first

    const char* url        = env_or("DASH_URL", "http://0.0.0.0:8000/");
    const char* pingHost   = env_or("DASH_PING_HOST", "0.0.0.0");
    const char* pingCount  = env_or("DASH_PING_COUNT", "2");
    const char* sleepMsStr = env_or("DASH_SLEEP_MS", "1500");
    const char* doPingStr  = env_or("DASH_DO_PING", "1");


    int sleepMs = atoi(sleepMsStr);
    int doPing  = atoi(doPingStr);

    if (sleepMs > 0) Sleep(sleepMs);
    if (doPing) { (void)do_ping(pingHost, pingCount); }

    // Awareness demo options (uncomment as needed)
    // system("start C:\\");
    // system("start calc.exe");

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "start %s", url);
    system(cmd);
    return 0;
}

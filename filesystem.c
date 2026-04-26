#include "kernel.h"

#define FS_MAX_FILES    32
#define FS_MAX_NAME     12
#define FS_MAX_SIZE   4096

typedef struct {
    char     name[FS_MAX_NAME];
    uint32_t size;
    uint8_t  data[FS_MAX_SIZE];
    bool     in_use;
} file_entry_t;

static file_entry_t files[FS_MAX_FILES];

/* ── String helpers (only used here; also exported via kernel.h) */
int strlen(const char *s) {
    int n = 0;
    while (s[n]) n++;
    return n;
}

int strcmp(const char *a, const char *b) {
    while (*a && *a == *b) { a++; b++; }
    return *(const unsigned char *)a - *(const unsigned char *)b;
}

void int_to_str(uint32_t n, char *buf, int base) {
    static const char digits[] = "0123456789ABCDEF";
    char tmp[32];
    int  i = 0;
    if (n == 0) { buf[0] = '0'; buf[1] = '\0'; return; }
    while (n) { tmp[i++] = digits[n % (uint32_t)base]; n /= (uint32_t)base; }
    int j = 0;
    while (i > 0) buf[j++] = tmp[--i];
    buf[j] = '\0';
}

char *strtok(char *str, const char *delim) {
    static char *saved = NULL;
    if (str) saved = str;
    if (!saved) return NULL;
    while (*saved && strchr(delim, *saved)) saved++;
    if (!*saved) { saved = NULL; return NULL; }
    char *tok = saved;
    while (*saved && !strchr(delim, *saved)) saved++;
    if (*saved) { *saved = '\0'; saved++; } else saved = NULL;
    return tok;
}

char *strchr(const char *s, int c) {
    while (*s) { if (*s == (char)c) return (char *)s; s++; }
    return NULL;
}

/* ── Filesystem API ─────────────────────────────────────────── */
void filesystem_init(void) {
    for (int i = 0; i < FS_MAX_FILES; i++) {
        files[i].in_use = false;
        files[i].size   = 0;
        memset(files[i].name, 0, FS_MAX_NAME);
    }
    file_create("AUTOEXEC.BAT", "@echo off\r\necho Welcome!\r\n");
    file_create("CONFIG.SYS",   "FILES=20\r\nBUFFERS=30\r\n");
    file_create("README.TXT",   "Simple MS-DOS v1.0\r\n");
    vga_puts("File system initialized\r\n");
}

uint8_t file_create(const char *filename, const char *content) {
    for (int i = 0; i < FS_MAX_FILES; i++) {
        if (files[i].in_use) continue;
        /* Copy name */
        int n = 0;
        while (filename[n] && n < FS_MAX_NAME - 1) {
            files[i].name[n] = filename[n]; n++;
        }
        files[i].name[n] = '\0';
        /* Copy content */
        if (content) {
            int l = 0;
            while (content[l] && l < FS_MAX_SIZE - 1) {
                files[i].data[l] = (uint8_t)content[l]; l++;
            }
            files[i].data[l] = 0;
            files[i].size = (uint32_t)l;
        }
        files[i].in_use = true;
        return (uint8_t)i;
    }
    return 0xFF;
}

uint8_t file_open(const char *filename) {
    for (int i = 0; i < FS_MAX_FILES; i++)
        if (files[i].in_use && strcmp(files[i].name, filename) == 0)
            return (uint8_t)i;
    return 0xFF;
}

uint32_t file_read(uint8_t handle, void *buffer, uint32_t size) {
    if (handle >= FS_MAX_FILES || !files[handle].in_use) return 0;
    uint32_t n = size < files[handle].size ? size : files[handle].size;
    memcpy(buffer, files[handle].data, n);
    return n;
}

uint32_t file_write(uint8_t handle, void *buffer, uint32_t size) {
    if (handle >= FS_MAX_FILES || !files[handle].in_use) return 0;
    uint32_t n = size < FS_MAX_SIZE ? size : FS_MAX_SIZE;
    memcpy(files[handle].data, buffer, n);
    files[handle].size = n;
    return n;
}

void     file_close(uint8_t handle) { (void)handle; }

uint32_t file_size(uint8_t handle) {
    if (handle >= FS_MAX_FILES || !files[handle].in_use) return 0;
    return files[handle].size;
}

bool file_exists(const char *filename) {
    return file_open(filename) != 0xFF;
}

void file_list(void) {
    vga_puts("Filename        Size\r\n");
    vga_puts("--------        ----\r\n");
    for (int i = 0; i < FS_MAX_FILES; i++) {
        if (!files[i].in_use) continue;
        vga_puts(files[i].name);
        int pad = 16 - strlen(files[i].name);
        while (pad-- > 0) vga_putchar(' ');
        char buf[12];
        int_to_str(files[i].size, buf, 10);
        vga_puts(buf);
        vga_puts("\r\n");
    }
}

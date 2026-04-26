#include "kernel.h"

#define PROMPT             "C:\\>"
#define MAX_CMD_LEN        128
#define MAX_ARGS           16

typedef struct {
    const char *name;
    void      (*func)(int argc, char *argv[]);
    const char *help;
} command_t;

/* Forward declarations */
static void cmd_help  (int argc, char *argv[]);
static void cmd_dir   (int argc, char *argv[]);
static void cmd_type  (int argc, char *argv[]);
static void cmd_cls   (int argc, char *argv[]);
static void cmd_ver   (int argc, char *argv[]);
static void cmd_echo  (int argc, char *argv[]);
static void cmd_exit  (int argc, char *argv[]);
static void cmd_mem   (int argc, char *argv[]);
static void cmd_reboot(int argc, char *argv[]);

static const command_t commands[] = {
    { "help",   cmd_help,   "Display this help message"      },
    { "dir",    cmd_dir,    "List files"                     },
    { "type",   cmd_type,   "Display file contents"          },
    { "cls",    cmd_cls,    "Clear the screen"               },
    { "ver",    cmd_ver,    "Show version"                   },
    { "echo",   cmd_echo,   "Print text to screen"           },
    { "exit",   cmd_exit,   "Halt the system"                },
    { "mem",    cmd_mem,    "Show memory usage"              },
    { "reboot", cmd_reboot, "Reboot the system"              },
};
static const int NUM_COMMANDS = (int)(sizeof(commands)/sizeof(commands[0]));

static char cmd_buf[MAX_CMD_LEN];
static int  cmd_pos;

/* ── Main shell loop ────────────────────────────────────────── */
void shell_main(void) {
    vga_puts("Simple MS-DOS Shell v1.0\r\n");
    vga_puts("Type 'help' for commands.\r\n\r\n");

    while (1) {
        vga_puts(PROMPT);
        cmd_pos = 0;
        cmd_buf[0] = '\0';

        while (1) {
            char c = keyboard_getchar();
            if (c == '\r') {
                vga_puts("\r\n");
                break;
            } else if (c == '\b') {
                if (cmd_pos > 0) {
                    cmd_pos--;
                    cmd_buf[cmd_pos] = '\0';
                    vga_putchar('\b');
                    vga_putchar(' ');
                    vga_putchar('\b');
                }
            } else if ((unsigned char)c >= 32 && cmd_pos < MAX_CMD_LEN - 1) {
                cmd_buf[cmd_pos++] = c;
                cmd_buf[cmd_pos]   = '\0';
                vga_putchar(c);
            }
        }
        shell_execute_command(cmd_buf);
    }
}

void shell_execute_command(char *cmd) {
    if (!cmd || strlen(cmd) == 0) return;

    char *argv[MAX_ARGS];
    int   argc = 0;
    char *tok  = strtok(cmd, " \t");
    while (tok && argc < MAX_ARGS) {
        argv[argc++] = tok;
        tok = strtok(NULL, " \t");
    }
    if (argc == 0) return;

    for (int i = 0; i < NUM_COMMANDS; i++) {
        if (strcmp(commands[i].name, argv[0]) == 0) {
            commands[i].func(argc, argv);
            return;
        }
    }
    vga_puts("Bad command or file name: ");
    vga_puts(argv[0]);
    vga_puts("\r\n");
}

/* ── Commands ───────────────────────────────────────────────── */
static void cmd_help(int argc, char *argv[]) {
    (void)argc; (void)argv;
    vga_puts("Available commands:\r\n\r\n");
    for (int i = 0; i < NUM_COMMANDS; i++) {
        vga_puts("  ");
        vga_puts(commands[i].name);
        int pad = 12 - strlen(commands[i].name);
        while (pad-- > 0) vga_putchar(' ');
        vga_puts("- ");
        vga_puts(commands[i].help);
        vga_puts("\r\n");
    }
}

static void cmd_dir(int argc, char *argv[]) {
    (void)argc; (void)argv;
    file_list();
}

static void cmd_type(int argc, char *argv[]) {
    if (argc < 2) { vga_puts("Usage: type <filename>\r\n"); return; }
    uint8_t h = file_open(argv[1]);
    if (h == 0xFF) {
        vga_puts("File not found: "); vga_puts(argv[1]); vga_puts("\r\n");
        return;
    }
    uint32_t sz = file_size(h);
    if (sz == 0) { vga_puts("(empty)\r\n"); file_close(h); return; }

    char *buf = (char *)kmalloc(sz + 1);
    if (!buf) { vga_puts("Out of memory\r\n"); file_close(h); return; }
    uint32_t n = file_read(h, buf, sz);
    buf[n] = '\0';
    vga_puts(buf);
    vga_puts("\r\n");
    kfree(buf);
    file_close(h);
}

static void cmd_cls(int argc, char *argv[]) {
    (void)argc; (void)argv;
    vga_clear();
}

static void cmd_ver(int argc, char *argv[]) {
    (void)argc; (void)argv;
    vga_puts("Simple MS-DOS v1.0\r\n");
}

static void cmd_echo(int argc, char *argv[]) {
    for (int i = 1; i < argc; i++) {
        if (i > 1) vga_putchar(' ');
        vga_puts(argv[i]);
    }
    vga_puts("\r\n");
}

static void cmd_exit(int argc, char *argv[]) {
    (void)argc; (void)argv;
    kernel_shutdown();
}

static void cmd_mem(int argc, char *argv[]) {
    (void)argc; (void)argv;
    uint32_t used = (uint32_t)((uint8_t *)heap_current - (uint8_t *)HEAP_START);
    uint32_t free_  = HEAP_SIZE - used;
    char buf[12];
    vga_puts("Heap used: "); int_to_str(used,  buf, 10); vga_puts(buf); vga_puts(" bytes\r\n");
    vga_puts("Heap free: "); int_to_str(free_, buf, 10); vga_puts(buf); vga_puts(" bytes\r\n");
}

static void cmd_reboot(int argc, char *argv[]) {
    (void)argc; (void)argv;
    vga_puts("Rebooting...\r\n");
    __asm__ volatile ("cli");
    while (1) { outb(0x64, 0xFE); __asm__ volatile ("hlt"); }
}

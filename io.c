#include "kernel.h"

static volatile uint16_t *vga_memory = (volatile uint16_t *)VGA_MEMORY;
static uint8_t  vga_color = 0x07; /* light grey on black */
static uint8_t  cursor_x  = 0;
static uint8_t  cursor_y  = 0;

/* ── Port I/O ───────────────────────────────────────────────── */
uint8_t inb(uint16_t port) {
    uint8_t result;
    __asm__ volatile ("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

void outb(uint16_t port, uint8_t data) {
    __asm__ volatile ("outb %0, %1" : : "a"(data), "Nd"(port));
}

/* ── VGA cursor ─────────────────────────────────────────────── */
void vga_set_cursor_pos(uint8_t x, uint8_t y) {
    cursor_x = x;
    cursor_y = y;
    uint16_t pos = (uint16_t)y * VGA_WIDTH + x;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

uint8_t vga_get_cursor_x(void) { return cursor_x; }
uint8_t vga_get_cursor_y(void) { return cursor_y; }

void vga_set_color(uint8_t color) { vga_color = color; }

void vga_clear(void) {
    uint16_t blank = ((uint16_t)vga_color << 8) | ' ';
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++)
        vga_memory[i] = blank;
    cursor_x = cursor_y = 0;
    vga_set_cursor_pos(0, 0);
}

void vga_init(void) {
    vga_color = (uint8_t)(VGA_COLOR_BLACK << 4) | VGA_COLOR_LIGHT_GREY;
    vga_clear();
}

/* ── VGA putchar ────────────────────────────────────────────── */
void vga_putchar(char c) {
    switch (c) {
    case '\r':
        cursor_x = 0;
        break;
    case '\n':
        cursor_x = 0;
        cursor_y++;
        break;
    case '\t':
        cursor_x = (uint8_t)((cursor_x + 8) & ~7);
        break;
    case '\b':
        if (cursor_x > 0) {
            cursor_x--;
            vga_memory[cursor_y * VGA_WIDTH + cursor_x] =
                ((uint16_t)vga_color << 8) | ' ';
        }
        break;
    default:
        if ((unsigned char)c >= 32) {
            vga_memory[cursor_y * VGA_WIDTH + cursor_x] =
                ((uint16_t)vga_color << 8) | (unsigned char)c;
            cursor_x++;
        }
        break;
    }

    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }

    /* Scroll */
    if (cursor_y >= VGA_HEIGHT) {
        for (int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; i++)
            vga_memory[i] = vga_memory[i + VGA_WIDTH];
        uint16_t blank = ((uint16_t)vga_color << 8) | ' ';
        for (int i = (VGA_HEIGHT - 1) * VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++)
            vga_memory[i] = blank;
        cursor_y = VGA_HEIGHT - 1;
    }

    vga_set_cursor_pos(cursor_x, cursor_y);
}

void vga_puts(const char *str) {
    while (*str) vga_putchar(*str++);
}

/* ── Keyboard ───────────────────────────────────────────────── */
/* Scancode-to-ASCII table (US QWERTY, unshifted) */
static const char scancode_to_ascii[58] = {
    0,   0,   '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
    '\t','q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\r',
    0,   'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'','`',
    0,   '\\','z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,   '*',
    0,   ' '
};

static volatile char  kb_char  = 0;
static volatile bool  kb_ready = false;

void keyboard_handler(void) {
    uint8_t scancode = inb(0x60);
    if (scancode & 0x80) return; /* key release – ignore */
    if (scancode < 58) {
        char c = scancode_to_ascii[scancode];
        if (c) {
            kb_char  = c;
            kb_ready = true;
        }
    }
}

char keyboard_getchar(void) {
    /* Spin until a key is available (interrupts must be enabled) */
    while (!kb_ready)
        __asm__ volatile ("hlt");
    kb_ready = false;
    return kb_char;
}

bool keyboard_available(void) {
    return kb_ready;
}

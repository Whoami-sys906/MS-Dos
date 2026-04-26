#ifndef IO_H
#define IO_H

#include "types.h"

#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

enum vga_color {
    VGA_COLOR_BLACK         = 0,
    VGA_COLOR_BLUE          = 1,
    VGA_COLOR_GREEN         = 2,
    VGA_COLOR_CYAN          = 3,
    VGA_COLOR_RED           = 4,
    VGA_COLOR_MAGENTA       = 5,
    VGA_COLOR_BROWN         = 6,
    VGA_COLOR_LIGHT_GREY    = 7,
    VGA_COLOR_DARK_GREY     = 8,
    VGA_COLOR_LIGHT_BLUE    = 9,
    VGA_COLOR_LIGHT_GREEN   = 10,
    VGA_COLOR_LIGHT_CYAN    = 11,
    VGA_COLOR_LIGHT_RED     = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN   = 14,
    VGA_COLOR_WHITE         = 15,
};

#define KEY_ENTER     0x1C
#define KEY_BACKSPACE 0x0E
#define KEY_ESC       0x01

void    vga_init(void);
void    vga_putchar(char c);
void    vga_puts(const char *str);
void    vga_clear(void);
void    vga_set_color(uint8_t color);
void    vga_set_cursor_pos(uint8_t x, uint8_t y);
uint8_t vga_get_cursor_x(void);
uint8_t vga_get_cursor_y(void);

char    keyboard_getchar(void);
bool    keyboard_available(void);

#endif

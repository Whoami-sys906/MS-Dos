#include "kernel.h"

extern void gdt_flush(void);

static void timer_handler_impl(void) {
    /* tick counter - can add scheduling here later */
    static uint32_t tick = 0;
    tick++;
}

static void keyboard_handler_wrapper_impl(void) {
    keyboard_handler();
}

/* Exposed so kernel.h declarations resolve */
void timer_handler(void)           { timer_handler_impl(); }
void keyboard_handler_wrapper(void){ keyboard_handler_wrapper_impl(); }

static void timer_init_impl(void) {
    register_irq_handler(0, timer_handler);
    uint32_t divisor = 1193180 / 100; /* ~100 Hz */
    outb(0x43, 0x36);
    outb(0x40, (uint8_t)(divisor & 0xFF));
    outb(0x40, (uint8_t)((divisor >> 8) & 0xFF));
}

void timer_init(void)    { timer_init_impl(); }
void keyboard_init(void) { register_irq_handler(1, keyboard_handler_wrapper); }

/* ── Kernel entry ───────────────────────────────────────────── */
void kernel_main(void) {
    vga_init();
    vga_puts("Simple MS-DOS Kernel v1.0\r\n");
    vga_puts("Copyright (c) 2024\r\n\r\n");

    gdt_flush();
    interrupts_init();
    memory_init();
    filesystem_init();
    keyboard_init();
    timer_init();

    vga_puts("\r\nKernel init complete. Starting shell...\r\n\r\n");
    shell_main();

    vga_puts("\r\nSystem halted.\r\n");
    __asm__ volatile ("cli; hlt");
}

void kernel_init(void)     { /* reserved */ }
void kernel_shutdown(void) {
    vga_puts("Shutting down...\r\n");
    __asm__ volatile ("cli; hlt");
}

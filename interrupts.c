#include "kernel.h"

/* ── IDT structures ─────────────────────────────────────────── */
typedef struct {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  zero;
    uint8_t  type_attr;
    uint16_t offset_high;
} __attribute__((packed)) idt_entry_t;

typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) idt_ptr_t;

static idt_entry_t idt[256];
static idt_ptr_t   idt_ptr;

/* Declared in kernel_asm.asm */
extern void isr0(void);  extern void isr1(void);  extern void isr2(void);
extern void isr3(void);  extern void isr4(void);  extern void isr5(void);
extern void isr6(void);  extern void isr7(void);  extern void isr8(void);
extern void isr9(void);  extern void isr10(void); extern void isr11(void);
extern void isr12(void); extern void isr13(void); extern void isr14(void);
extern void isr15(void); extern void isr16(void); extern void isr17(void);
extern void isr18(void); extern void isr19(void); extern void isr20(void);
extern void isr21(void); extern void isr22(void); extern void isr23(void);
extern void isr24(void); extern void isr25(void); extern void isr26(void);
extern void isr27(void); extern void isr28(void); extern void isr29(void);
extern void isr30(void); extern void isr31(void);

extern void irq0(void);  extern void irq1(void);  extern void irq2(void);
extern void irq3(void);  extern void irq4(void);  extern void irq5(void);
extern void irq6(void);  extern void irq7(void);  extern void irq8(void);
extern void irq9(void);  extern void irq10(void); extern void irq11(void);
extern void irq12(void); extern void irq13(void); extern void irq14(void);
extern void irq15(void);

/* ── IRQ handler table ──────────────────────────────────────── */
static void (*irq_handlers[16])(void);

/* ── Helpers ────────────────────────────────────────────────── */
static void idt_set_gate(uint8_t n, uint32_t handler) {
    idt[n].offset_low  = (uint16_t)(handler & 0xFFFF);
    idt[n].offset_high = (uint16_t)((handler >> 16) & 0xFFFF);
    idt[n].selector    = 0x08;
    idt[n].zero        = 0;
    idt[n].type_attr   = 0x8E; /* present, ring-0, 32-bit interrupt gate */
}

/* ── PIC remapping ──────────────────────────────────────────── */
void pic_init(void) {
    outb(0x20, 0x11); outb(0xA0, 0x11); /* ICW1 */
    outb(0x21, 0x20); outb(0xA1, 0x28); /* ICW2: remap IRQ0-15 to INT 32-47 */
    outb(0x21, 0x04); outb(0xA1, 0x02); /* ICW3 */
    outb(0x21, 0x01); outb(0xA1, 0x01); /* ICW4 */
    outb(0x21, 0x00); outb(0xA1, 0x00); /* unmask all IRQs */
}

/* ── IDT init ───────────────────────────────────────────────── */
void idt_init(void) {
    memset(&idt, 0, sizeof(idt));

    /* CPU exceptions */
    idt_set_gate(0,  (uint32_t)isr0);  idt_set_gate(1,  (uint32_t)isr1);
    idt_set_gate(2,  (uint32_t)isr2);  idt_set_gate(3,  (uint32_t)isr3);
    idt_set_gate(4,  (uint32_t)isr4);  idt_set_gate(5,  (uint32_t)isr5);
    idt_set_gate(6,  (uint32_t)isr6);  idt_set_gate(7,  (uint32_t)isr7);
    idt_set_gate(8,  (uint32_t)isr8);  idt_set_gate(9,  (uint32_t)isr9);
    idt_set_gate(10, (uint32_t)isr10); idt_set_gate(11, (uint32_t)isr11);
    idt_set_gate(12, (uint32_t)isr12); idt_set_gate(13, (uint32_t)isr13);
    idt_set_gate(14, (uint32_t)isr14); idt_set_gate(15, (uint32_t)isr15);
    idt_set_gate(16, (uint32_t)isr16); idt_set_gate(17, (uint32_t)isr17);
    idt_set_gate(18, (uint32_t)isr18); idt_set_gate(19, (uint32_t)isr19);
    idt_set_gate(20, (uint32_t)isr20); idt_set_gate(21, (uint32_t)isr21);
    idt_set_gate(22, (uint32_t)isr22); idt_set_gate(23, (uint32_t)isr23);
    idt_set_gate(24, (uint32_t)isr24); idt_set_gate(25, (uint32_t)isr25);
    idt_set_gate(26, (uint32_t)isr26); idt_set_gate(27, (uint32_t)isr27);
    idt_set_gate(28, (uint32_t)isr28); idt_set_gate(29, (uint32_t)isr29);
    idt_set_gate(30, (uint32_t)isr30); idt_set_gate(31, (uint32_t)isr31);

    /* Hardware IRQs (remapped to 32-47) */
    idt_set_gate(32, (uint32_t)irq0);  idt_set_gate(33, (uint32_t)irq1);
    idt_set_gate(34, (uint32_t)irq2);  idt_set_gate(35, (uint32_t)irq3);
    idt_set_gate(36, (uint32_t)irq4);  idt_set_gate(37, (uint32_t)irq5);
    idt_set_gate(38, (uint32_t)irq6);  idt_set_gate(39, (uint32_t)irq7);
    idt_set_gate(40, (uint32_t)irq8);  idt_set_gate(41, (uint32_t)irq9);
    idt_set_gate(42, (uint32_t)irq10); idt_set_gate(43, (uint32_t)irq11);
    idt_set_gate(44, (uint32_t)irq12); idt_set_gate(45, (uint32_t)irq13);
    idt_set_gate(46, (uint32_t)irq14); idt_set_gate(47, (uint32_t)irq15);

    idt_ptr.limit = sizeof(idt) - 1;
    idt_ptr.base  = (uint32_t)&idt;
    __asm__ volatile ("lidt %0" : : "m"(idt_ptr));
}

void interrupts_init(void) {
    pic_init();
    idt_init();
    __asm__ volatile ("sti");
}

/* ── C-level handlers called from assembly stubs ────────────── */
void isr_handler(uint32_t interrupt) {
    vga_puts("Exception #");
    char buf[4];
    int_to_str(interrupt, buf, 10);
    vga_puts(buf);
    vga_puts(" - system halted\r\n");
    __asm__ volatile ("cli; hlt");
}

void irq_handler(uint32_t irq) {
    /* Send End-Of-Interrupt */
    if (irq >= 8)
        outb(0xA0, 0x20); /* slave PIC EOI */
    outb(0x20, 0x20);     /* master PIC EOI */

    if (irq < 16 && irq_handlers[irq])
        irq_handlers[irq]();
}

void register_irq_handler(uint8_t irq, void (*handler)(void)) {
    if (irq < 16)
        irq_handlers[irq] = handler;
}

void syscall_handler(uint32_t eax, uint32_t ebx,
                     uint32_t ecx, uint32_t edx) {
    (void)ecx; (void)edx;
    switch (eax) {
    case SYS_EXIT:  vga_puts("Process exited\r\n");      break;
    case SYS_WRITE: vga_puts((const char *)ebx);         break;
    default:
        vga_puts("Unknown syscall\r\n");
        break;
    }
}

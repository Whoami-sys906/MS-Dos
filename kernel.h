#ifndef KERNEL_H
#define KERNEL_H

#include "types.h"
#include "io.h"

/* DOS-compatible system call numbers */
#define SYS_EXIT  0x00
#define SYS_WRITE 0x02
#define SYS_READ  0x03
#define SYS_OPEN  0x06
#define SYS_CLOSE 0x07
#define SYS_EXEC  0x4B

/* Memory layout */
#define HEAP_START 0x10000
#define HEAP_SIZE  0x10000
#define STACK_SIZE 0x2000

typedef struct {
    uint32_t pid;
    uint32_t esp;
    uint32_t eip;
    bool     active;
} process_t;

/* Kernel functions */
void  kernel_main(void);
void  kernel_init(void);
void  kernel_shutdown(void);

/* Memory functions */
void  memory_init(void);
void *kmalloc(uint32_t size);
void  kfree(void *ptr);
extern uint8_t *heap_current;

/* Filesystem functions */
void     filesystem_init(void);
uint8_t  file_create(const char *filename, const char *content);
uint8_t  file_open(const char *filename);
uint32_t file_read(uint8_t handle, void *buffer, uint32_t size);
uint32_t file_write(uint8_t handle, void *buffer, uint32_t size);
void     file_close(uint8_t handle);
void     file_list(void);
uint32_t file_size(uint8_t handle);
bool     file_exists(const char *filename);

/* Interrupt functions */
void interrupts_init(void);
void idt_init(void);
void pic_init(void);
void register_irq_handler(uint8_t irq, void (*handler)(void));

/* Port I/O */
uint8_t inb(uint16_t port);
void    outb(uint16_t port, uint8_t data);

/* Hardware handlers */
void timer_init(void);
void timer_handler(void);
void keyboard_init(void);
void keyboard_handler(void);
void keyboard_handler_wrapper(void);

/* ISR/IRQ C-level handlers called from assembly */
void isr_handler(uint32_t interrupt);
void irq_handler(uint32_t interrupt);

/* Shell */
void shell_main(void);
void shell_execute_command(char *command);

/* String utilities */
int   strlen(const char *str);
int   strcmp(const char *str1, const char *str2);
void  int_to_str(uint32_t num, char *str, int base);
void *memcpy(void *dest, const void *src, uint32_t count);
void *memset(void *dest, uint8_t val, uint32_t count);
int   memcmp(const void *ptr1, const void *ptr2, uint32_t count);
char *strtok(char *str, const char *delim);
char *strchr(const char *str, int c);

#endif

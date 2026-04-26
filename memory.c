#include "kernel.h"

static uint8_t *heap_start   = (uint8_t *)HEAP_START;
static uint8_t *heap_end     = (uint8_t *)(HEAP_START + HEAP_SIZE);
       uint8_t *heap_current = (uint8_t *)HEAP_START;

void memory_init(void) {
    heap_current = heap_start;
    vga_puts("Memory manager initialized\r\n");
}

void *kmalloc(uint32_t size) {
    /* Align to 4 bytes */
    size = (size + 3) & ~3U;
    if (heap_current + size > heap_end) {
        vga_puts("Error: out of memory\r\n");
        return NULL;
    }
    void *ptr = heap_current;
    heap_current += size;
    return ptr;
}

void kfree(void *ptr) {
    (void)ptr; /* bump allocator – no free */
}

void *memcpy(void *dest, const void *src, uint32_t count) {
    uint8_t       *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;
    while (count--) *d++ = *s++;
    return dest;
}

void *memset(void *dest, uint8_t val, uint32_t count) {
    uint8_t *d = (uint8_t *)dest;
    while (count--) *d++ = val;
    return dest;
}

int memcmp(const void *ptr1, const void *ptr2, uint32_t count) {
    const uint8_t *p1 = (const uint8_t *)ptr1;
    const uint8_t *p2 = (const uint8_t *)ptr2;
    while (count--) {
        if (*p1 != *p2) return *p1 - *p2;
        p1++; p2++;
    }
    return 0;
}

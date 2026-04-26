[bits 32]
[global _start]
[global gdt_flush]
[global idt_flush]

; ISR stubs (no error code)
%macro ISR_NOERR 1
[global isr%1]
isr%1:
    push dword 0
    push dword %1
    jmp isr_common_stub
%endmacro

; ISR stubs (CPU pushes error code)
%macro ISR_ERR 1
[global isr%1]
isr%1:
    push dword %1
    jmp isr_common_stub
%endmacro

; IRQ stubs
%macro IRQ 2
[global irq%1]
irq%1:
    push dword 0
    push dword %2
    jmp irq_common_stub
%endmacro

section .text

; ── Kernel entry ────────────────────────────────────────────────
_start:
    mov esp, stack_top
    call kernel_main
    cli
    hlt
    jmp $

; ── GDT / IDT flush ─────────────────────────────────────────────
gdt_flush:
    lgdt [gdt_descriptor]
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x08:flush_cs
flush_cs:
    ret

idt_flush:
    lidt [idt_descriptor_stub]
    ret

; ── ISR stubs ───────────────────────────────────────────────────
ISR_NOERR  0
ISR_NOERR  1
ISR_NOERR  2
ISR_NOERR  3
ISR_NOERR  4
ISR_NOERR  5
ISR_NOERR  6
ISR_NOERR  7
ISR_ERR    8
ISR_NOERR  9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_ERR   21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_ERR   30
ISR_NOERR 31

; ── IRQ stubs ───────────────────────────────────────────────────
IRQ  0, 32
IRQ  1, 33
IRQ  2, 34
IRQ  3, 35
IRQ  4, 36
IRQ  5, 37
IRQ  6, 38
IRQ  7, 39
IRQ  8, 40
IRQ  9, 41
IRQ 10, 42
IRQ 11, 43
IRQ 12, 44
IRQ 13, 45
IRQ 14, 46
IRQ 15, 47

; ── Common ISR stub ─────────────────────────────────────────────
; Stack on entry: [interrupt_number, error_code, eip, cs, eflags]
isr_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    ; pass interrupt number (at esp+48 after all pushes)
    mov eax, [esp+48]
    push eax
    call isr_handler
    add esp, 4
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8          ; remove error_code + interrupt_number
    iret

; ── Common IRQ stub ─────────────────────────────────────────────
irq_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, [esp+48]   ; interrupt number (remapped: 32-47)
    sub eax, 32         ; convert to IRQ number 0-15
    push eax
    call irq_handler
    add esp, 4
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8
    iret

; ── External declarations ───────────────────────────────────────
extern isr_handler
extern irq_handler
extern kernel_main

; ── BSS ─────────────────────────────────────────────────────────
section .bss
stack_bottom:
    resb 8192
stack_top:

; ── Data ────────────────────────────────────────────────────────
section .data

gdt:
    dq 0x0000000000000000   ; null
    dq 0x00CF9A000000FFFF   ; 0x08 code
    dq 0x00CF92000000FFFF   ; 0x10 data
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt

; Placeholder; the real IDT descriptor is built by idt_init() in C
idt_descriptor_stub:
    dw 0
    dd 0

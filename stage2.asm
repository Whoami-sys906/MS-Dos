[org 0x0000]
[bits 16]

; Loaded at 0x0800:0x0000 = linear 0x8000
start:
    ; Fix segment registers
    mov ax, 0x0800
    mov ds, ax
    mov es, ax

    mov si, stage2_msg
    call print_string

    ; Load kernel: 16 sectors from sector 4 -> linear 0x10000
    mov ah, 0x02
    mov al, 0x10        ; 16 sectors (8 KB)
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x04        ; sector 4
    mov bx, 0x1000      ; 0x1000:0x0000 = 0x10000
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error

    cmp al, 0x10
    ; Show success message
    mov si, kernel_msg
    call print_string
    
    ; Set up segments for kernel
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; Jump to 16-bit kernel
    jmp 0x1000:0x0000

    ; Enable A20 line
    in  al, 0x92
    or  al, 0x02
    out 0x92, al

    ; Load GDT
    cli
    xor ax, ax
    mov ds, ax          ; DS=0 for GDT address
    lgdt [gdt_descriptor]

    ; Switch to protected mode
    mov eax, cr0
    or  eax, 0x01
    mov cr0, eax

    ; Far jump flushes prefetch and sets CS=0x08
    jmp 0x08:protected_mode

[bits 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    ; stack below 0xA0000

    ; Jump to kernel entry at 0x10000
    jmp 0x08:0x10000

; ── 16-bit helpers ──────────────────────────────────────────────
[bits 16]
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

disk_error:
    mov si, err_msg
    call print_string
    cli
    hlt
    jmp $

; ── GDT ─────────────────────────────────────────────────────────
align 8
gdt:
    dq 0x0000000000000000   ; null descriptor
    dq 0x00CF9A000000FFFF   ; 0x08 kernel code (32-bit, 4 GB)
    dq 0x00CF92000000FFFF   ; 0x10 kernel data (32-bit, 4 GB)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1
    dd gdt              ; physical address (stage2 is at 0x8000, gdt offset within)

; ── Messages ────────────────────────────────────────────────────
stage2_msg  db 'Loading kernel...', 0x0D, 0x0A, 0
kernel_msg  db 'Kernel loaded! Entering protected mode...', 0x0D, 0x0A, 0
err_msg     db 'Disk error in stage2!', 0x0D, 0x0A, 0

times 1024-($-$$) db 0   ; pad to 2 sectors

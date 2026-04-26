[org 0x7C00]
[bits 16]

BOOT_DRIVE db 0

start:
    mov [BOOT_DRIVE], dl

    mov ax, 0x0003
    int 0x10

    mov si, boot_msg
    call print_string

    ; reset disk
    mov ah, 0x00
    mov dl, [BOOT_DRIVE]
    int 0x13
    jc disk_error

    ; load kernel
    mov ah, 0x02
    mov al, 0x20
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x01

    mov bx, 0x1000
    mov es, bx
    xor bx, bx

    mov dl, [BOOT_DRIVE]
    int 0x13
    jc disk_error

    cmp al, 0x20
    jne disk_error

    mov si, success_msg
    call print_string

    ; jump to kernel (REAL MODE)
    jmp 0x1000:0000

; ======================
print_string:
.next:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    ret

disk_error:
    mov si, error_msg
    call print_string
    jmp $

boot_msg db 'Booting...',13,10,0
success_msg db 'Kernel loaded!',13,10,0
error_msg db 'Disk error!',13,10,0

times 510-($-$$) db 0
dw 0xAA55
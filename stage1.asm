[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive
    mov [boot_drive], dl

    ; Clear screen
    mov ax, 0x0003
    int 0x10

    mov si, boot_msg
    call print_string

    ; Reset disk
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Load stage2 (2 sectors, starting at sector 2)
    mov ah, 0x02
    mov al, 0x02        ; 2 sectors
    mov ch, 0x00        ; cylinder 0
    mov dh, 0x00        ; head 0
    mov cl, 0x02        ; sector 2
    mov bx, 0x0800      ; load to 0x0800:0x0000 = 0x8000
    mov es, bx
    xor bx, bx
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    cmp al, 0x02
    jne disk_error

    mov si, ok_msg
    call print_string

    ; Far jump to stage2
    jmp 0x0800:0x0000

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

boot_drive  db 0
boot_msg    db 'Simple MS-DOS Booting...', 0x0D, 0x0A, 0
ok_msg      db 'Stage 2 loaded!', 0x0D, 0x0A, 0
err_msg     db 'Disk error!', 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xAA55

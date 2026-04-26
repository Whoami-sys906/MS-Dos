[org 0x1000]
[bits 16]

; Minimal test kernel
start:
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Print 'X' to show kernel is running
    mov ah, 0x0E
    mov al, 'X'
    int 0x10
    
    ; Print message
    mov si, test_msg
    mov ah, 0x0E
print_loop:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print_loop
done:
    
    ; Halt
    cli
    hlt
    jmp $

test_msg db 'TEST KERNEL RUNNING', 0x0D, 0x0A, 0

times 8192-($-$$) db 0

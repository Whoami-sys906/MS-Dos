[org 0x1000]
[bits 16]

start:
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Show test message
    mov si, test_msg
    mov ah, 0x0E
print_loop:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print_loop
done:
    
    ; Simple wait for key
wait_key:
    mov ah, 0x00
    int 0x16
    
    ; Echo the key
    mov ah, 0x0E
    int 0x10
    
    jmp wait_key

test_msg db 'MINIMAL KERNEL - TYPE ANY KEY', 0x0D, 0x0A, 0

times 8192-($-$$) db 0

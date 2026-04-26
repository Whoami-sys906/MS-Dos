[org 0x1000]
[bits 16]

start:
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Show startup message
    mov si, startup_msg
    mov ah, 0x0E
print_loop:
    lodsb
    cmp al, 0
    je show_prompt
    int 0x10
    jmp print_loop

show_prompt:
    ; Show prompt
    mov si, prompt
    mov ah, 0x0E
prompt_loop:
    lodsb
    cmp al, 0
    je wait_key
    int 0x10
    jmp prompt_loop

wait_key:
    ; Wait for keypress (non-blocking check first)
    mov ah, 0x01
    int 0x16
    jz wait_key  ; No key available, keep waiting
    
    ; Key available, read it
    mov ah, 0x00
    int 0x16
    
    ; Echo the key
    mov ah, 0x0E
    int 0x10
    
    ; Check for ESC to exit
    cmp al, 0x1B
    je exit_system
    
    jmp wait_key

exit_system:
    ; Clear screen and show exit message
    mov ax, 0x0003
    int 0x10
    mov si, exit_msg
    mov ah, 0x0E
exit_loop:
    lodsb
    cmp al, 0
    je halt
    int 0x10
    jmp exit_loop

halt:
    cli
    hlt
    jmp $

startup_msg db 'Simple MS-DOS v1.0 - READY', 0x0D, 0x0A, 0
prompt db 'C:\> ', 0
exit_msg db 'System halted - Press any key to reboot', 0x0D, 0x0A, 0

times 8192-($-$$) db 0

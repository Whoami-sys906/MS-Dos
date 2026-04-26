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
    ; Show prompt and wait for input
    mov si, prompt
    mov ah, 0x0E
prompt_loop:
    lodsb
    cmp al, 0
    je wait_input
    int 0x10
    jmp prompt_loop

wait_input:
    ; Wait for keypress
    mov ah, 0x00
    int 0x16
    
    ; Echo the key
    mov ah, 0x0E
    int 0x10
    
    ; Simple loop - just keep waiting for keys
    jmp wait_input

startup_msg db 'Simple MS-DOS v1.0 - READY', 0x0D, 0x0A, 0
prompt db 'C:\> ', 0

times 8192-($-$$) db 0

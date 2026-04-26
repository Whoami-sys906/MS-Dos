[org 0x1000]
[bits 16]

start:
    mov ax, 0x0003
    int 0x10
    
    ; test
    mov ah, 0x0E
    mov al, 'K'
    int 0x10
    
    mov si, kernel_msg
    call print_string
    
    mov si, prompt
    call print_string
    
    ; Simple buffer clear
    mov di, command_buffer
    mov cx, 128
    xor al, al
    rep stosb
    
main_loop:
    mov ah, 0
    int 0x16

    cmp al, 0x0D
    je process_command

    cmp al, 0x08
    je backspace

    cmp al, 32
    jb main_loop
    cmp al, 126
    ja main_loop

    ; length
    mov di, command_buffer
    call strlen
    cmp ax, 127
    jae main_loop

    ; echo
    mov ah, 0x0E
    int 0x10

    ; store char
    mov di, command_buffer
    add di, ax
    mov [di], al

    jmp main_loop

backspace:
    mov di, command_buffer
    call strlen
    test ax, ax
    jz main_loop

    dec ax
    add di, ax
    mov byte [di], 0

    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10

    jmp main_loop

process_command:
    mov al, 13
    mov ah, 0x0E
    int 0x10
    mov al, 10
    int 0x10

    mov si, command_buffer
    call strlen
    test ax, ax
    jz show_prompt

    mov si, command_buffer
    mov di, cmd_help
    call strcmp
    test ax, ax
    jz do_help

    mov si, command_buffer
    mov di, cmd_cls
    call strcmp
    test ax, ax
    jz do_cls

    mov si, command_buffer
    mov di, cmd_ver
    call strcmp
    test ax, ax
    jz do_ver

    mov si, command_buffer
    mov di, cmd_dir
    call strcmp
    test ax, ax
    jz do_dir

    mov si, command_buffer
    mov di, cmd_exit
    call strcmp
    test ax, ax
    jz do_exit

    mov si, bad_command
    call print_string
    jmp show_prompt

do_help:
    mov si, help_text
    call print_string
    jmp show_prompt

do_cls:
    mov ax, 0x0003
    int 0x10
    jmp show_prompt

do_ver:
    mov si, version_text
    call print_string
    jmp show_prompt

do_dir:
    mov si, dir_header
    call print_string

    mov si, filename1
    call print_string
    mov si, filename2
    call print_string
    mov si, filename3
    call print_string

    jmp show_prompt

do_exit:
    cli
    hlt
    jmp $

show_prompt:
    mov di, command_buffer
    mov cx, 128
    xor al, al
    rep stosb

    mov si, prompt
    call print_string

    jmp main_loop

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

; ✅ FIXED strlen (uses DI correctly)
strlen:
    push di
    xor ax, ax
.loop:
    cmp byte [di], 0
    je .done
    inc ax
    inc di
    jmp .loop
.done:
    pop di
    ret

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .diff
    test al, al
    jz .eq
    inc si
    inc di
    jmp .loop
.diff:
    mov ax, 1
    ret
.eq:
    xor ax, ax
    ret

; ======================
; DATA
command_buffer times 128 db 0

cmd_help db 'help',0
cmd_cls  db 'cls',0
cmd_ver  db 'ver',0
cmd_dir  db 'dir',0
cmd_exit db 'exit',0

kernel_msg db 'Simple MS-DOS Kernel v1.0',13,10,0
prompt db 'C:\> ',0
bad_command db 'Bad command or file name',13,10,0

help_text db 'Commands:',13,10
          db 'HELP CLS VER DIR EXIT',13,10,0

version_text db 'Version 1.0',13,10,0

dir_header db 'Files:',13,10,0
filename1 db 'AUTOEXEC.BAT',13,10,0
filename2 db 'CONFIG.SYS',13,10,0
filename3 db 'README.TXT',13,10,0

times 8192-($-$$) db 0
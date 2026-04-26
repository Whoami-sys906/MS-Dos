[org 0x0000]
[bits 16]
; Loaded at 0x1000:0x0000 = linear 0x10000
; This is the 16-bit real-mode kernel / shell (standalone, no C)

FILE_ENTRY_SIZE equ 16
MAX_FILES       equ 8
MAX_FILENAME    equ 12

start:
    ; Fix segment registers
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    mov ax, 0x0003      ; text mode 80x25
    int 0x10

    call filesystem_init

    mov si, kernel_msg
    call print_string

main_loop:
    mov si, prompt
    call print_string

    ; Clear input buffer
    mov di, command_buffer
    mov cx, 128
    xor al, al
    rep stosb

input_loop:
    mov ah, 0x00
    int 0x16

    cmp al, 0x0D        ; Enter
    je  execute_command
    cmp al, 0x08        ; Backspace
    je  handle_backspace
    cmp al, 0x1B        ; Escape -> clear line
    je  main_loop

    cmp al, 32
    jb  input_loop
    cmp al, 126
    ja  input_loop

    ; Length check
    mov di, command_buffer
    call strlen
    cmp ax, 127
    jae input_loop

    ; Append character
    mov di, command_buffer
    add di, ax
    mov [di], al

    mov ah, 0x0E
    int 0x10
    jmp input_loop

handle_backspace:
    mov di, command_buffer
    call strlen
    test ax, ax
    jz   input_loop

    dec ax
    add di, ax
    mov byte [di], 0

    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp input_loop

execute_command:
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    int 0x10

    call process_command
    jmp  main_loop

; ── Command dispatch ────────────────────────────────────────────
process_command:
    mov si, command_buffer
    call strlen
    test ax, ax
    jz   .done

    mov si, command_buffer
    mov di, str_help
    call strcmp
    jz   do_help

    mov si, command_buffer
    mov di, str_dir
    call strcmp
    jz   do_dir

    mov si, command_buffer
    mov di, str_cls
    call strcmp
    jz   do_cls

    mov si, command_buffer
    mov di, str_ver
    call strcmp
    jz   do_ver

    mov si, command_buffer
    mov di, str_exit
    call strcmp
    jz   do_exit

    mov si, bad_command
    call print_string
.done:
    ret

do_help:
    mov si, help_text
    call print_string
    ret

do_dir:
    call filesystem_list
    ret

do_cls:
    mov ax, 0x0003
    int 0x10
    ret

do_ver:
    mov si, version_text
    call print_string
    ret

do_exit:
    mov si, halt_msg
    call print_string
    cli
    hlt
    jmp $

; ── String helpers ──────────────────────────────────────────────
; print_string: SI = ptr to NUL-terminated string
print_string:
    lodsb
    test al, al
    jz   .done
    mov  ah, 0x0E
    int  0x10
    jmp  print_string
.done:
    ret

; strlen: DI = string -> AX = length
strlen:
    push di
    xor  ax, ax
.loop:
    cmp  byte [di], 0
    je   .done
    inc  ax
    inc  di
    jmp  .loop
.done:
    pop  di
    ret

; strcmp: SI, DI -> ZF set if equal
strcmp:
.loop:
    mov  al, [si]
    mov  bl, [di]
    cmp  al, bl
    jne  .neq
    test al, al
    jz   .eq
    inc  si
    inc  di
    jmp  .loop
.neq:
    or   ax, 1      ; ZF=0
    ret
.eq:
    xor  ax, ax     ; ZF=1
    ret

; print_number: AX = number
print_number:
    push ax
    push bx
    push cx
    push dx
    xor  cx, cx
    mov  bx, 10
.div:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  .div
.prn:
    pop  dx
    add  dl, '0'
    mov  al, dl
    mov  ah, 0x0E
    int  0x10
    loop .prn
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret

; ── Filesystem ──────────────────────────────────────────────────
; Entry layout (16 bytes):
;   [0]      used flag (1=used)
;   [1..12]  filename (NUL padded)
;   [13]     reserved
;   [14..15] size (word)

filesystem_init:
    ; Zero out file table
    mov  di, files
    mov  cx, MAX_FILES * FILE_ENTRY_SIZE
    xor  al, al
    rep  stosb

    ; Create default files
    mov  si, autoexec_name
    mov  ax, 64
    call fs_create
    mov  si, config_name
    mov  ax, 32
    call fs_create
    mov  si, readme_name
    mov  ax, 128
    call fs_create
    ret

; fs_create: SI=name, AX=size
fs_create:
    push ax
    mov  di, files
    mov  cx, MAX_FILES
.find:
    cmp  byte [di], 0
    je   .found
    add  di, FILE_ENTRY_SIZE
    loop .find
    pop  ax
    ret
.found:
    mov  byte [di], 1   ; mark used
    ; copy name to [di+1]
    push di
    add  di, 1
    mov  cx, MAX_FILENAME
.cpname:
    mov  al, [si]
    mov  [di], al
    inc  si
    inc  di
    test al, al
    jz   .cpname_done
    loop .cpname
.cpname_done:
    pop  di
    pop  ax
    mov  [di+14], ax    ; store size
    ret

filesystem_list:
    mov  si, dir_header
    call print_string

    mov  di, files
    mov  cx, MAX_FILES
.loop:
    cmp  byte [di], 0
    je   .next

    ; print name
    push di
    add  di, 1
    mov  si, di
    call print_string
    pop  di

    ; spacing
    mov  si, tab_str
    call print_string

    ; print size
    mov  ax, [di+14]
    call print_number

    mov  si, newline
    call print_string

.next:
    add  di, FILE_ENTRY_SIZE
    loop .loop
    ret

; ── Data ────────────────────────────────────────────────────────
command_buffer  times 128 db 0
files           times (MAX_FILES * FILE_ENTRY_SIZE) db 0

str_help    db 'help', 0
str_dir     db 'dir',  0
str_cls     db 'cls',  0
str_ver     db 'ver',  0
str_exit    db 'exit', 0

kernel_msg   db 'Simple MS-DOS Kernel v1.0', 13, 10
             db "Type 'help' for commands.", 13, 10, 13, 10, 0
prompt       db 'C:\> ', 0
bad_command  db 'Bad command or file name', 13, 10, 0
halt_msg     db 'System halted.', 13, 10, 0

help_text    db 'Commands: help dir cls ver exit', 13, 10, 0
version_text db 'Simple MS-DOS v1.0', 13, 10, 0
dir_header   db 'Filename     Size', 13, 10
             db '--------     ----', 13, 10, 0
tab_str      db '     ', 0
newline      db 13, 10, 0

autoexec_name db 'AUTOEXEC.BAT', 0
config_name   db 'CONFIG.SYS',   0
readme_name   db 'README.TXT',   0

times 8192-($-$$) db 0   ; pad to 16 sectors

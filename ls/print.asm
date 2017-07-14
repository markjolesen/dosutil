; PRINT.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

include io.inc

.data

extrn scratch:byte
extrn _opt_uF:byte, _opt_p:byte

.code

extrn puts:near
extrn sl_itoa:near, sl_ltoa:near

; ds:si file buffer
public file_is_exe
file_is_exe proc

    push si
    push di
    push es
    
    push ds
    pop es
    add si, offset fi_name
    
file_is_exe_next:
    lodsb
    or al, al
    jz file_is_exe_exit_false
    cmp al, '.'
    jnz file_is_exe_next
    
    lodsb 
    mov di, si ; save for resets
    
    cmp al, 'E'
    jnz file_is_exe_check_com
    lodsb
    cmp al, 'X'
    jnz file_is_exe_check_com
    lodsb
    cmp al, 'E'
    jnz file_is_exe_check_com
    mov ax, 1
    jmp file_is_exe_exit
    
file_is_exe_check_com:
    mov si, di
    cmp al, 'C'
    jnz file_is_exe_check_bat
    lodsb
    cmp al, 'O'
    jnz file_is_exe_check_bat
    lodsb
    cmp al, 'M'
    jnz file_is_exe_check_bat
    mov ax, 2
    jmp file_is_exe_exit
    
file_is_exe_check_bat:
    mov si, di
    cmp al, 'B'
    jnz file_is_exe_exit_false
    lodsb
    cmp al, 'A'
    jnz file_is_exe_exit_false
    lodsb
    cmp al, 'T'
    jnz file_is_exe_exit_false
    mov ax, 2
    jmp file_is_exe_exit
    
file_is_exe_exit_false:
    xor ax, ax
    
file_is_exe_exit:

    pop es
    pop di
    pop si

    ret
file_is_exe endp

; ds:si file buffer
public print_file
print_file proc

    push di
    
    mov di, si
    add si, offset fi_name
    call puts
    
    cmp byte ptr es:[_opt_uF], 0
    jz print_file_switch_p
    
    mov al, byte ptr [di].fi_attr
    and al, FILE_SUBDIRECTORY 
    jz print_file_check_exe
    
    mov ah, 02h
    mov dl, '\'
    int 21h
    jmp print_file_exit
    
print_file_check_exe:
    mov si, di
    call file_is_exe
    or ax, ax
    jz print_file_exit

    mov ah, 02h
    mov dl, '*'
    int 21h
    jmp print_file_exit

print_file_switch_p:
    cmp byte ptr es:[_opt_p], 0
    jz print_file_exit

    mov al, byte ptr [di].fi_attr
    and al, FILE_SUBDIRECTORY 
    jz print_file_exit
    
    mov ah, 02h
    mov dl, '\'
    int 21h

print_file_exit:    
    
    pop di
    
    ret
print_file endp

; ds:si file buffer
public print_time
print_time proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    
    push bp 
    mov bp, sp 
    sub sp, 04h
    ; [bp - 2] hour
    ; [bp - 4] minutes
    
    ; hour
    mov ax, word ptr [si].fi_time
    shr ax, 11
    mov word ptr [bp - 2], ax
    
    ; minutes
    mov ax, word ptr [si].fi_time
    shr ax, 5
    and ax, 03fh
    mov word ptr [bp - 4], ax
    
    push es
    pop ds
    
    lea di, scratch
    mov si, di
    
    ; print hour
    mov ax, word ptr [bp - 2]
    call sl_itoa
    
    cmp byte ptr [si+1], 0
    jnz hour_no_pad
    
    mov ah, 02h
    mov dl, '0'
    int 21h
    
hour_no_pad:    

    call puts
    
    mov ah, 02h
    mov dl, ':'
    int 21h
    
    ; print minutes
    mov ax, word ptr [bp - 4]
    call sl_itoa
    
    cmp byte ptr [si+1], 0
    jnz minute_no_pad
    
    mov ah, 02h
    mov dl, '0'
    int 21h
    
minute_no_pad:    

    call puts

    mov ah, 02h
    mov dl, ' '
    int 21h
    
    mov sp, bp
    pop bp 
    
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_time endp

; ds:si file buffer
public print_date
print_date proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    
    push bp 
    mov bp, sp 
    sub sp, 06h
    ; [bp - 2] year
    ; [bp - 4] month
    ; [bp - 6] day
    
    ; year
    mov ax, word ptr [si].fi_date
    shr ax, 9
    add ax, 1980
    mov word ptr [bp - 2], ax
    
    ; month
    mov ax, word ptr [si].fi_date
    shr ax, 5
    and ax, 0fh
    mov word ptr [bp - 4], ax
    
    ; day
    mov ax, word ptr [si].fi_date
    and ax, 01fh 
    mov word ptr [bp - 6], ax
    
    push es
    pop ds
    
    lea di, scratch
    mov si, di
    
    ; print month
    mov ax, word ptr [bp - 4]
    call sl_itoa
    
    cmp byte ptr [si+1], 0
    jnz month_no_pad
    
    mov ah, 02h
    mov dl, '0'
    int 21h
    
month_no_pad:    

    call puts
    
    mov ah, 02h
    mov dl, '-'
    int 21h
   
    ; print day 
    mov ax, word ptr [bp - 6]
    call sl_itoa
    
    cmp byte ptr [si+1], 0
    jnz day_no_pad
    
    mov ah, 02h
    mov dl, '0'
    int 21h
   
day_no_pad:    

    call puts    
    
    mov ah, 02h
    mov dl, '-'
    int 21h
    
    ; print year
    mov ax, word ptr [bp - 2]
    call sl_itoa
    call puts
    
    mov ah, 02h
    mov dl, ' '
    int 21h
    
    mov sp, bp
    pop bp 
    
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_date endp

; ds:si file buffer 
public print_size
print_size proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds

    mov ax, word ptr [si].fi_size
    mov dx, word ptr [si].fi_size+2
    lea di, scratch
    call sl_ltoa
    
    push es
    pop ds
    
    ; strlen
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx
    
    mov ax, 10 ; max digits
    sub ax, cx
    mov cx, ax
print_size_space:
    mov ah, 02h
    mov dl, ' '
    int 21h
    loop print_size_space
    
    lea si, scratch
    call puts
    
    mov ah, 02h
    mov dl, ' '
    int 21h
    
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret
print_size endp

; ds:si file buffer
public print_attributes 
print_attributes proc

    mov al, byte ptr [si].fi_attr
    and al, FILE_ARCHIVE
    jz no_archive
    
    mov ah, 02h
    mov dl, 'A'
    int 21h
    jmp switch_subdirectory
     
no_archive:
    mov ah, 02h
    mov dl, '-'
    int 21h

switch_subdirectory:    
    mov al, byte ptr [si].fi_attr
    and al, FILE_SUBDIRECTORY
    jz no_subdirectory
    
    mov ah, 02h
    mov dl, 'D'
    int 21h
    jmp switch_volume_label
     
no_subdirectory:
    mov ah, 02h
    mov dl, '-'
    int 21h
    
switch_volume_label:
    mov al, byte ptr [si].fi_attr
    and al, FILE_VOLUME_LABEL
    jz no_volume_label
    
    mov ah, 02h
    mov dl, 'V'
    int 21h
    jmp switch_system
   
no_volume_label:
    mov ah, 02h
    mov dl, '-'
    int 21h
    
switch_system:
    mov al, byte ptr [si].fi_attr
    and al, FILE_SYSTEM
    jz no_system_label
    
    mov ah, 02h
    mov dl, 'S'
    int 21h
    jmp switch_hidden

no_system_label:   
    mov ah, 02h
    mov dl, '-'
    int 21h
    
switch_hidden:
    mov al, byte ptr [si].fi_attr
    and al, FILE_HIDDEN
    jz no_hidden
    
    mov ah, 02h
    mov dl, 'H'
    int 21h
    jmp switch_read_only
    
no_hidden:    
    mov ah, 02h
    mov dl, '-'
    int 21h

switch_read_only:    
    mov al, byte ptr [si].fi_attr
    and al, FILE_READ_ONLY
    jz no_read_only
    
    mov ah, 02h
    mov dl, 'H'
    int 21h
    jmp print_attributes_exit
    
no_read_only:
    mov ah, 02h
    mov dl, '-'
    int 21h
    
print_attributes_exit:
    mov ah, 02h
    mov dl, ' '
    int 21h

    ret
print_attributes endp

end

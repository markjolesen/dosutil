; MKDIR.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

include io.inc

.data?

extrn dta:disk_transfer_area
path db 128 dup(?)

.data

error_create db 'Unable to create directory: ', 0
lf db 0dh, 0ah, 0

.code

extrn puts:near

; ds:si directory component to create
public mkdir
mkdir proc

    push cx
    push dx
    push si
    push di

    lea di, path
    
    push si
mkdir_copy:
    lodsb
    stosb
    or al, al
    jnz mkdir_copy
    pop si

    mov byte ptr [di+0], '\'
    mov byte ptr [di+1], '*'
    mov byte ptr [di+2], '.'
    mov byte ptr [di+3], '*'
    mov byte ptr [di+4], 0
    
    ; find first file
    mov cx, 111111b
    lea dx, path
    mov ah, 04eh
    int 21h
    jnc mkdir_exit_success
    
    ; create directory
    mov dx, si
    mov ah, 39h
    int 21h
    jnc mkdir_exit_success
    
    push si
    lea si, error_create
    call puts
    pop si
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp mkdir_exit
    
mkdir_exit_success:
    xor ax, ax

mkdir_exit:

    pop di
    pop si
    pop dx
    pop cx

    ret
mkdir endp

end

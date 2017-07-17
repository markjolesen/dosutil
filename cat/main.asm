; MAIN.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CAT. This work is published 
; from: United States.

.186
.model small

include io.inc

.stack 2048

.data?

extrn _opt_h:byte, _opt_u:byte
extrn file_list:byte
extrn _buffer_size:word

public dta

dta disk_transfer_area 1 dup(?)

.code

extrn usage_print:near, option_parse:near
extrn process:near, process_file:near

main proc

    cld
    mov ax, @DATA
    mov ds, ax
    push ds
    pop es
    
    call option_parse
    or ax, ax
    jnz main_exit
    cmp byte ptr [_opt_h], 0
    jz main_options
    call usage_print
    jmp main_exit
    
main_options:
    cmp byte ptr [_opt_u], 0
    jz  main_start
    mov word ptr [_buffer_size], 1

main_start:

    ; set disk transfer area
    mov ah, 1ah
    lea dx, dta
    int 21h
    
    lea si, file_list
    cmp byte ptr [si], 0
    jz main_stdin

main_next_file:
    mov ax, si
    call process_file

    ; next file in list
    xor ax, ax
    mov cx, 258 ; size of file list
    mov di, si
    repne scasb
    mov si, di
    cmp byte ptr [si], 0
    jz main_exit
    jmp main_next_file

main_stdin:
    xor ax, ax ; stdin
    call process

main_exit:
    ; al = exit code
    mov ah, 4ch ; exit
    int 21h

main endp

end main

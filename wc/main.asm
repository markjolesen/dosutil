; MAIN.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to WC. This work is published 
; from: United States.

.186
.model small

include io.inc

.stack 2048

.data?

extrn _opt_h:byte
extrn file_list:byte
extrn files_printed:word

public dta

dta disk_transfer_area 1 dup(?)

.code

extrn usage_print:near, option_parse:near
extrn process:near, process_file:near
extrn print_total:near

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
    jz main_start
    call usage_print
    jmp main_exit
    
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
    lea si, dta.dta_name
    mov byte ptr [si+0], 's'
    mov byte ptr [si+1], 't'
    mov byte ptr [si+2], 'd'
    mov byte ptr [si+3], 'i'
    mov byte ptr [si+4], 'n'
    mov byte ptr [si+5], 0
    xor ax, ax ; stdin
    call process

main_exit:
    cmp word ptr [files_printed], 1
    jle main_exit2

    call print_total

main_exit2:
    ; al = exit code
    mov ah, 4ch ; exit
    int 21h

main endp

end main

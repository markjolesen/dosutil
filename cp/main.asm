; MAIN.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CP. This work is published 
; from: United States.

.186
.model small

include io.inc

.stack 2048

.data?

public dta

dta disk_transfer_area 1 dup(?)

.data

extrn _opt_h:byte

.code

extrn usage_print:near, option_parse:near
extrn process:near

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

    call process

main_exit:
    ; al = exit code
    mov ah, 4ch ; exit
    int 21h

main endp

end main

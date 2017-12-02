; MAIN.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.stack 2048

include io.inc

.data?

public dta, scratch

dta disk_transfer_area 1 dup(?)
scratch db 128 dup(?)

.data

extrn _opt_h:byte
extrn path:byte
extrn file_list:byte
extrn buffer_slot:word

public lf

file_offset dw 0
lf db 0dh, 0ah, 0

.code

extrn usage_print:near, option_parse:near
extrn fetch_dir:near
extrn process:near
extrn filebuf_init:near, filebuf_deinit:near
extrn dirbuf_init:near, dirbuf_deinit:near
extrn path_pop:near

main proc

    cld
    mov ax, @DATA
    mov ds, ax

    ; free unused memory not used by app
    mov ah, 62h ; get PSP returns bx = seg of PSP
    int 21h
    mov es, bx ; es = segment to resize
    mov bx, (1024 * 10) / 16 
    mov ah, 04ah
    int 21h
    
    push ds
    pop es
    
    call dirbuf_init
    or ax, ax
    jnz main_exit
    
    call filebuf_init
    or ax, ax
    jnz main_exit
    
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
    
    cmp byte ptr [file_list], 0
    jz main_fetch_all
    
main_fetch_list:
    mov byte ptr [path], 0
    mov word ptr [buffer_slot], 0
  
    ; copy file name into path
    lea si, file_list
    add si, word ptr [file_offset]
    lea di, path
    
    xor cx, cx
main_fetch_list_copy:
    lodsb
    or al, al
    jz main_fetch_list_copy_end
    stosb
    inc cx
    jmp main_fetch_list_copy
    
main_fetch_list_copy_end:
    mov byte ptr es:[di], 0
    mov ax, word ptr [file_offset]
    add ax, cx
    inc ax
    mov word ptr [file_offset], ax
    or cx, cx
    jz main_exit
    
    mov al, byte ptr es:[di-1]
    cmp al, '*'
    jz main_fetch_list_checkwildcard
    cmp al, '\'
    jz main_fetch_list_appendwildcard
    cmp al, ':'
    jz main_fetch_list_appendbackslash
    cmp al, '.'
    jnz main_fetch_list_check_type
    cmp cx, 1
    jz main_fetch_list_appendbackslash
    cmp byte ptr es:[di-1], '.'
    jz main_fetch_list_appendbackslash
    mov byte ptr es:[di+0], '*'
    mov byte ptr es:[di+1], '0'
    jmp main_fetch_list_start
    
main_fetch_list_checkwildcard:
    cmp cx, 1
    jz main_fetch_list_hasonestar
    mov al, byte ptr es:[di-2]
    cmp al, '\'
    jz main_fetch_list_hasonestar
    cmp al, ':'
    jz main_fetch_list_hasonestar
    jmp main_fetch_list_start

main_fetch_list_hasonestar:
    dec di
    jmp main_fetch_list_appendwildcard

main_fetch_list_check_type:
    ; find first file
    mov cx, 111111b
    lea dx, path
    mov ah, 04eh
    int 21h
    jc main_fetch_list_start
    mov al, [byte ptr dta.dta_attr]
    test al, FILE_SUBDIRECTORY
    jz main_fetch_list_start
    
main_fetch_list_appendbackslash:
    mov byte ptr es:[di+0], '\'
    inc di
    
main_fetch_list_appendwildcard:
    mov byte ptr es:[di+0], '*'
    mov byte ptr es:[di+1], '.'
    mov byte ptr es:[di+2], '*'
    mov byte ptr es:[di+3], 0
    
main_fetch_list_start:
    lea ax, path
    call fetch_dir
    or ax, ax
    jnz main_fetch_list
    call path_pop
    call process
    jmp main_fetch_list
    
main_fetch_all:
    lea si, path
    mov byte ptr [si+0], '*'
    mov byte ptr [si+1], '.'
    mov byte ptr [si+2], '*'
    mov byte ptr [si+3], 0
    mov ax, si
    mov word ptr [buffer_slot], 0
    call fetch_dir
    mov byte ptr [si+0], '.'
    mov byte ptr [si+1], '\'
    mov byte ptr [si+2], 0
    call process

main_exit:
    call filebuf_deinit
    call dirbuf_deinit
    ; al = exit code
    mov ah, 4ch ; exit
    int 21h

main endp


end main

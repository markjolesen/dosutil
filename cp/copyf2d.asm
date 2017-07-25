; COPYF2D.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CP. This work is published 
; from: United States.

.186
.model small

.data?

path db 128 dup(?)

.code

extrn copyfile:near

; copies a file to a directory
; inputs:
;   ds:si source file 
;   ds:di target directory 
;
public copyf2d
copyf2d proc

    push bx
    push cx
    push dx
    push si
    push di

    push bp 
    mov bp, sp 
    sub sp, 04h
    ; [bp - 2] source file 
    ; [bp - 4] target directory
    mov word ptr [bp - 2], si
    mov word ptr [bp - 4], di

    ; extract file name from source

    ; goto end of string
    mov di, si
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx

    ; search backwards for backslash
    mov si, di
    dec si
    std
copyf2d_find_path:
    lodsb
    cmp al, '\'
    jz copyf2d_copy_to_path
    loop copyf2d_find_path
    dec si

copyf2d_copy_to_path:
    cld
    inc si
    mov dx, si ; save

    ; copy target directory into path
    mov si, word ptr [bp - 4]
    lea di, path

copyf2d_next_char:
    lodsb
    stosb
    or al, al
    jnz copyf2d_next_char

    mov byte ptr [di-1], '\'
    mov si, dx
    
copyf2d_next_char2:
    lodsb
    stosb
    or al, al
    jnz copyf2d_next_char2
    
    mov si, word ptr [bp - 2]
    lea di, path
    call copyfile

    mov sp, bp
    pop bp 
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
copyf2d endp

end

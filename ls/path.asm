; PATH.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.data?

public path
path db 128 dup(?)

.data

public path_length
path_length dw 0

.code

; dx:ax directory name to append onto path (0 terminated)
; es = ds
;
public path_push
path_push proc

    push cx
    push si
    push di
    push ds

    mov cx, word ptr [path_length]
    mov si, ax
    lea di, path
    add di, cx
    mov ds, dx
    or cx, cx
    jz path_push_append
    mov byte ptr es:[di], '\'
    inc di
    inc cx
    
path_push_append:
    lodsb
    or al, al
    jz path_push_exit
    stosb
    inc cx
    jmp path_push_append
    
path_push_exit:
    mov byte ptr es:[di], 0
    
    pop ds
    mov word ptr [path_length], cx
    pop di
    pop si
    pop cx

    ret
path_push endp

; remove last directory name component in path
public path_pop
path_pop proc

    push ax
    push cx
    push si

    lea si, path
    mov cx, word ptr [path_length]
    or cx, cx
    jz path_pop_exit
    add si, cx
    std
    
path_pop_next:
    lodsb
    cmp al, '\'
    jz path_pop_exit
    dec cx
    jnz path_pop_next

path_pop_exit:    

    mov byte ptr [si+1], 0
    mov word ptr [path_length], cx
    
    pop si
    pop cx
    pop ax
    
    cld
    ret
path_pop endp

end

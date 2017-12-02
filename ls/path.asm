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
    
    ; goto end of string
    mov si, ax
    lea di, path
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    dec di

    mov ds, dx
    or cx, cx
    jz path_push_append
    cmp byte ptr es:[di-1], '\'
    jz path_push_append
    mov byte ptr es:[di], '\'
    inc di
    inc cx
    
path_push_append:
    lodsb
    or al, al
    jz path_push_exit
    stosb
    jmp path_push_append
    
path_push_exit:
    mov byte ptr es:[di], 0
    
    pop ds
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
    push di

    ; goto end of string
    lea di, path
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx
    jz path_pop_end
    dec di
    dec di
    mov si, di
    
    std
    
path_pop_next:
    lodsb
    cmp al, '\'
    jz path_pop_found
    loop path_pop_next
    
path_pop_add_null:    
    mov byte ptr [si+1], 0
    jmp path_pop_end

path_pop_found:
    cmp cx, 1
    jnz path_pop_add_null
    mov byte ptr [si+2], 0
    
path_pop_end:
    lea si, path
    cmp byte ptr [si], 0
    jnz path_pop_exit
    mov byte ptr [si+0], '.'
    mov byte ptr [si+1], '\'
    mov byte ptr [si+2], 0
    
path_pop_exit:
    pop di
    pop si
    pop cx
    pop ax
    
    cld
    
    ret
path_pop endp

end

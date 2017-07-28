; PATH.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

.data

.code

; dx:si path (0 terminated)
; dx:di name to append onto path (0 terminated)
public path_push
path_push proc

    push ax
    push cx
    push si
    push di

    cmp byte ptr [di], 0
    jz path_push_exit

    ; goto end of string
    push di
    mov di, si
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx
    dec di
    mov si, di
    pop di
    xchg si, di

    or cx, cx
    jz path_push_append
    cmp byte ptr [di], '\'
    jz path_push_append
    mov byte ptr [di], '\'
    inc di
    
path_push_append:
    lodsb
    or al, al
    jz path_push_exit
    stosb
    jmp path_push_append
    
path_push_exit:
    mov byte ptr [di], 0
    
    pop di
    pop si
    pop cx
    pop ax

    ret
path_push endp

; remove last directory component from path
; ds:si path
public path_pop
path_pop proc

    push ax
    push cx
    push si
    push di

    mov di, si
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    dec di
    not cx
    dec cx
    or cx, cx
    jz path_pop_exit
    mov si, di
    
path_pop_next:
    cmp byte ptr [si], '\'
    jz path_pop_exit
    dec si
    loop path_pop_next

path_pop_exit:    

    mov byte ptr [si], 0
    
    pop di
    pop si
    pop cx
    pop ax
    
    ret
path_pop endp

end

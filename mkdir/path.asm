; PATH.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

.code

; remove superfluous backslashes from a path 
;
; inputs:
;   ds:si path to process
;
; ouputs:
;   ax length of string
;
public path_strip_superfluous_backslash
path_strip_superfluous_backslash proc

    push cx
    push si
    push di

    xor cx, cx
    mov di, si
    
path_strip_start:
    lodsb
    or al, al
    jz path_strip_exit 
    cmp al, '\'
    jnz path_strip_store
    
    stosb
    inc cx

path_strip_next:
    lodsb
    or al, al
    jz path_strip_exit 
    cmp al, '\'
    jz path_strip_next
    
path_strip_store: 
    stosb
    inc cx
    jmp path_strip_start

path_strip_exit:
    mov [byte ptr di], 0
    mov ax, cx

    pop di
    pop si
    pop cx

    ret
path_strip_superfluous_backslash endp

end

; PROCESS.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

.data?

scratch db 128 dup(?)

.data

extrn _opt_p:byte

.code

extrn mkdir:near
extrn path_strip_superfluous_backslash:near

; ds:si path to process
public process 
process proc

    push cx
    push dx
    push si
    push di
    
    lea di, scratch
    
process_copy:
    lodsb
    stosb 
    or al, al
    jnz process_copy
    
    lea si, scratch
    call path_strip_superfluous_backslash
    or ax, ax
    jz process_exit

    cmp [byte ptr _opt_p], 0
    jz process_default

    mov di, si ; di = head, si = tail
    xor cx, cx ; component length
    xor dx, dx ; indicator component continues

    ; skip drive component
    cmp ax, 3
    jb process_component_start 
    cmp [byte ptr si+1], ':'
    jnz process_component_start
    cmp [byte ptr si+2], '\'
    jnz process_component_start
    inc si
    inc si
    inc si
    mov cx, 3

process_component_start:
    lodsb
    or al, al
    jz process_component
    cmp al, '\'
    jz process_component_backslash
    inc cx
    jmp process_component_start

process_component_backslash:
    mov [byte ptr si-1], 0
    mov dx, 1

process_component:
    or cx, cx
    jz process_exit
    push si
    mov si, di
    call mkdir
    pop si
    or dx, dx
    jz process_exit
    xor dx, dx
    xor cx, cx
    mov [byte ptr si-1], '\'
    jmp process_component_start

process_default:
    call mkdir

process_exit:

    pop di
    pop si
    pop dx
    pop cx

    ret
process endp

end

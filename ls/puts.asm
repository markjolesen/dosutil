; PUTS.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.code

; write character to stdout
; inputs:
;  ds:si ASCIZ string to write
; returns:
;  ax bytes written
; destroys:
;  ax
public puts
puts proc

    push cx
    push dx
    push si

    xor cx, cx

puts_next:
    lodsb
    or al, al
    jz puts_exit
    mov ah, 02h
    mov dl, al
    int 21h
    inc cx
    jmp puts_next

puts_exit:
    mov ax, cx

    pop si
    pop dx
    pop cx

    ret
puts endp

end

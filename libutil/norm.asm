; NORM.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LIBUTIL. This work is published 
; from: United States.

.186
.model small

.data

.code

; norm_stripdot (private)
;
; strips dot followed by backslash
; 
; inputs:
;
;   ds:si ASCIIZ path
;   es:di 256 byte (ASCIIZ) output buffer
;
; outputs:
;
;   es:di processed path
;   
; destroys:
;
;   ax
;
norm_stripdot proc

    push si
    push di
    
norm_stripdot_again:
    
    lodsb
    or al, al
    jz norm_stripdot_exit
    
    cmp al, '.'
    jz norm_stripdot_case_dot
    
    stosb
    jmp norm_stripdot_again

norm_stripdot_case_dot:

    cmp byte ptr [si], '.'
    jnz norm_stripdot_case_backslash
   
norm_stripdot_skip_dot:

    stosb
    lodsb
    cmp al, '.'
    jz norm_stripdot_skip_dot
    
    or al, al
    jz norm_stripdot_exit
    
    stosb
    jmp norm_stripdot_again 
    
norm_stripdot_case_backslash:

    cmp byte ptr [si], '\'
    jz norm_stripdot_skip_char
    
    cmp byte ptr [si], 0
    jz norm_stripdot_exit
    
    stosb
    jmp norm_stripdot_again
    
norm_stripdot_skip_char:

    inc si
    jmp norm_stripdot_again    

norm_stripdot_exit:

    mov byte ptr es:[di], 0

    pop di
    pop si
    
    ret
norm_stripdot endp

; norm_strip (private)
;
;   strips a path of specific repeating characters ('*', '\')
;
; inputs:
;
;   ds:si ASCIIZ path
;   es:di 256 byte (ASCIIZ) output buffer
;
; outputs:
;
;   es:di processed path
;   
; destroys:
;
;   ax
;
norm_strip proc

    push si
    push di

norm_strip_again:

    lodsb
    
    or al, al
    jz norm_strip_exit
    
    stosb
    
    cmp al, '*'
    jz norm_strip_dup
    
    cmp al, '\'
    jz norm_strip_dup
    
    jmp norm_strip_again
    
norm_strip_dup:

    cmp al, byte ptr [si]
    jnz norm_strip_again
    inc si
    jmp norm_strip_dup
    
norm_strip_exit:
    
    mov byte ptr es:[di], 0

    pop di
    pop si

    ret

norm_strip endp

; norm_replace_question (private)
;
; replaces question marks with an asterik
; 
; inputs:
;
;   ds:si ASCIIZ path
;
; outputs:
;
;   none
; 
; destroys:
;
;   ax
;
; returns:
;
;   none
;
norm_replace_question proc

    push si
    
norm_replace_question_next:

    lodsb
    or al, al
    jz norm_replace_question_exit   
    
    cmp al, '\'
    jz norm_replace_question_exit   
    
    cmp al, '.'
    jz norm_replace_question_exit   
    
    cmp al, '?'
    jnz norm_replace_question_next
    
    mov byte ptr [si-1], '*'
    jmp norm_replace_question_next
    
norm_replace_question_exit:
    
    pop si

    ret
norm_replace_question endp


; norm_stripq (private)
;
;   strips superflous question marks
;
; inputs:
;
;   ds:si ASCIIZ path
;
; outputs:
;
;   none
;   
; destroys:
;
;   none
;
norm_stripq proc

    push di
    push si
    push cx
    push bx
    push ax
    
    xor bx, bx
    xor cx, cx
    
    mov di, si
    
norm_stripq_next:

    lodsb
    or al, al
    jnz norm_stripq_switch
    
    or cx, cx
    jz norm_stripq_exit
    
    or bx, bx
    jz norm_stripq_exit
    
    mov si, di
    call norm_replace_question
    jmp norm_stripq_exit

norm_stripq_switch:

    cmp al, '?'
    jnz norm_stripq_case_asterik
    
    inc bx
    jmp norm_stripq_next
    
norm_stripq_case_asterik:

    cmp al, '*'
    jnz norm_stripq_case_backslash
    
    inc cx
    jmp norm_stripq_next
    
norm_stripq_case_backslash:

    cmp al, '\'
    jz norm_stripq_case_replace
    
    cmp al, '.'
    jnz norm_stripq_next
    
norm_stripq_case_replace:
    
    or cx, cx
    jz norm_stripq_reset
    
    or bx, bx
    jz norm_stripq_reset
    
    push si
    mov si, di
    call norm_replace_question
    pop si
   
norm_stripq_reset:
    mov di, si
    xor cx, cx
    xor bx, bx
    jmp norm_stripq_next

norm_stripq_exit:

    pop ax
    pop bx
    pop cx
    pop si
    pop di
    
    ret
norm_stripq endp

; norm_wild (private)
norm_wild proc

    push cx
    push si
    push di
    push ds
    push es

    xor cx, cx

norm_wild_strcpy:

    lodsb
    stosb
    or al, al
    jz norm_wild_end
    inc cx
    jmp norm_wild_strcpy
    
norm_wild_end: 

    dec si
    dec di
    or cx, cx
    jz norm_wild_add_wild
    
norm_wild_scan_backslash:
   
    dec si
    dec di
    dec cx
    or cx, cx
    jz norm_wild_start
    cmp byte ptr [si], '\'
    jnz norm_wild_scan_backslash
    inc si
    inc di
    
norm_wild_start:

    xor cx, cx ; length
    
norm_wild_scan_dot:

    lodsb
    inc di
    or al, al
    jz norm_wild_end_dot
    cmp al, '.'
    jnz norm_wild_scan_dot

    cmp byte ptr [si], '.'
    jz norm_wild_exit
    
    or cx, cx
    jnz norm_wild_ext
    
    mov byte ptr [di-1], '*'
    mov byte ptr [di], '.'
    inc di

norm_wild_ext:

    jmp norm_wild_exit
    
norm_wild_end_dot:

    or cx, cx
    jz norm_wild_add_wild
    jmp norm_wild_exit
    
norm_wild_add_wild:

    mov byte ptr es:[di+0], '*'
    mov byte ptr es:[di+1], '.'
    mov byte ptr es:[di+2], '*'
    mov byte ptr es:[di+3], 0
    
norm_wild_exit:
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    
    cld

    ret
norm_wild endp


; norm_fix (public)
;
;   normalize a path
;
; inputs:
;
;   ds:si ASCIIZ path
;   es:di 256 byte (ASCIIZ) output buffer
;
; outputs:
;
;   none
;
; destroys:
;
;   ax
;
public norm_fix
norm_fix proc

    push bp
    mov bp, sp
    sub sp, 512
   
    push cx
    push ds
    push es

    push di
    push ds    
    
    push ss
    pop es
    lea di, [bp - 256]
    
norm_fix_copystr:

    lodsb
    stosb
    or al, al
    jnz norm_fix_copystr
    
    push es
    pop ds
    
    lea si, [bp - 256]
    call norm_stripq
    
    lea di, [bp - 512]
    call norm_strip
    
    mov si, di   
    lea di, [bp - 256]
    call norm_stripdot
    
    mov si, di
    pop es
    pop di
    xor cx, cx
   
norm_fix_clip:
    
    lodsb
    or al, al
    jz norm_fix_wild
    inc cx
    cmp al, '\'
    jnz norm_fix_clip
    cmp byte ptr [si], 0
    jnz norm_fix_clip
    cmp cx, 1
    jz norm_fix_wild
    mov byte ptr [si-1], 0
    
norm_fix_wild:
    
    lea si, [bp - 256]
    call norm_wild
    
    pop es
    pop ds
    pop cx
    
    mov sp, bp
    pop bp

    ret
norm_fix endp

end

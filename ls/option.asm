; OPTION.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.data?

; list of file names. each file name is null terminated. 
; DOS command line is limited to 127 characters. 
public file_list
file_list db 258 dup(?)

.data

public _opt_uA, _opt_uC, _opt_uF, _opt_uR, _opt_uS
public _opt_a, _opt_f, _opt_h, _opt_l, _opt_m, _opt_p
public _opt_r, _opt_t, _opt_x, _opt_1 

; error message
bad_arg db "Invalid option '"
bad_op db " '", 0dh, 0ah, "use -h for help$"

_opt_uA db 0
_opt_uC db 0
_opt_uF db 0
_opt_uR db 0
_opt_uS db 0
_opt_a db 0
_opt_f db 0
_opt_h db 0
_opt_l db 0
_opt_m db 0
_opt_p db 0
_opt_r db 0
_opt_t db 0
_opt_x db 0
_opt_1 db 0

.code

; internal to option_parse
; process rest of command line, which are file names
; inputs:
;   ds:si points to remainder of command line
;   es data segment
; outputs:
;   fills file_list with a list of null terminated file names. 
; destroys:
;  ax, di
; 
parse_files proc

    lea di, file_list
    
parse_skip_spaces:

    lodsb
    cmp al, 0dh
    jz parse_exit
    cmp al, ' '
    jz parse_skip_spaces
    
parse_next:
    stosb
    lodsb
    cmp al, 0dh
    jz parse_exit
    cmp al, ' '
    jnz parse_next
    mov byte ptr es:[di], 0
    inc di
    jmp parse_skip_spaces

parse_exit:
    mov byte ptr es:[di], 0
    mov byte ptr es:[di+1], 0
    
    ret
parse_files endp

; parse command line options
; inputs:
;  none
; returns:
;  ax 0 success
;  ax !0 failure
; destroys:
;  ax, bx, di, si
public option_parse
option_parse proc

    push ds
    
    mov byte ptr [file_list], 0
    
    ; get PSP 
    ; returns: bx= seg of PSP
    mov ah, 62h 
    int 21h
    mov ds, bx
    mov si, 81h ; point to command line offset 81h
    
op_skip_space:
    lodsb
    cmp al, 0dh
    jz op_exit_success
    cmp al, ' '
    jz op_skip_space
    
    mov byte ptr es:[bad_op], al
    cmp al, '-'
    jnz op_set_filenames
    
op_next_arg:
    lodsb
    mov byte ptr es:[bad_op], al
    cmp al, 0dh
    jnz op_switch
    
op_badarg:
    pop ds
    push ds
    mov ah, 09h
    mov dx, offset bad_arg
    int 21h
    mov ax, -1
    jmp op_exit
    
op_switch:

    cmp al, 'A'
    jnz op_uC
    mov byte ptr es:[_opt_uA], 1
    jmp op_switch_end
    
op_uC:   
    cmp al, 'C'
    jnz op_uF
    mov byte ptr es:[_opt_uC], 1
    jmp op_switch_end
    
op_uF:
    cmp al, 'F'
    jnz op_uR
    mov byte ptr es:[_opt_uF], 1
    jmp op_switch_end
    
op_uR: 
    cmp al, 'R'
    jnz op_uS
    mov byte ptr es:[_opt_uR], 1
    jmp op_switch_end
    
op_uS:    
    cmp al, 'S'
    jnz op_a
    mov byte ptr es:[_opt_uS], 1
    jmp op_switch_end
    
op_a:    
    cmp al, 'a'
    jnz op_f
    mov byte ptr es:[_opt_a], 1
    jmp op_switch_end
    
op_f:
    cmp al, 'f'
    jnz op_h
    mov byte ptr es:[_opt_f], 1
    jmp op_switch_end
    
op_h:    
    cmp al, 'h'
    jnz op_l
    mov byte ptr es:[_opt_h], 1
    jmp op_switch_end
    
op_l:
    cmp al, 'l'
    jnz op_m
    mov byte ptr es:[_opt_l], 1
    jmp op_switch_end
    
op_m:
    cmp al, 'm'
    jnz op_p
    mov byte ptr es:[_opt_m], 1
    jmp op_switch_end
    
op_p:
    cmp al, 'p'
    jnz op_r
    mov byte ptr es:[_opt_p], 1
    jmp op_switch_end
    
op_r:
    cmp al, 'r'
    jnz op_t
    mov byte ptr es:[_opt_r], 1
    jmp op_switch_end
    
op_t:
    cmp al, 't'
    jnz op_x
    mov byte ptr es:[_opt_t], 1
    jmp op_switch_end
    
op_x:
    cmp al, 'x'
    jnz op_1
    mov byte ptr es:[_opt_x], 1
    jmp op_switch_end
    
op_1:
    cmp al, '1'
    jnz op_badarg
    mov byte ptr es:[_opt_1], 1

op_switch_end:
    mov al, byte ptr ds:[si]
    cmp al, 0dh
    jz op_exit_success
    cmp al, ' '
    jz op_skip_space
    jmp op_next_arg
    
op_set_filenames:
    dec si
    call parse_files

op_exit_success:
    xor ax, ax
    
op_exit:

    pop ds

    ret
option_parse endp

end


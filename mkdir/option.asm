; OPTION.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

.data?

; list of file names. each file name is null terminated. 
; DOS command line is limited to 127 characters. 
public file_list
file_list db 258 dup(?)

.data

public file_last, file_count
file_last dw 0
file_count db 0

; error message
bad_arg db "Invalid option '"
bad_op db " '", 0dh, 0ah, "use -h for help$"

public _opt_h, _opt_p

_opt_h db 0
_opt_p db 0

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
    mov byte ptr es:[file_count], 0
    mov word ptr es:[file_last], di
 
parse_skip_spaces:

    lodsb
    cmp al, 0dh
    jz parse_exit
    cmp al, ' '
    jz parse_skip_spaces
    
    mov word ptr es:[file_last], di
    inc byte ptr es:[file_count]

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
    jz op_exit_sucess
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

    cmp al, 'h'
    jnz op_p
    mov byte ptr es:[_opt_h], 1
    jmp op_switch_end

op_p:
    cmp al, 'p'
    jnz op_badarg
    mov byte ptr es:[_opt_p], 1

op_switch_end:
    mov al, byte ptr ds:[si]
    cmp al, 0dh
    jz op_exit_sucess
    cmp al, ' '
    jz op_skip_space
    jmp op_next_arg
    
op_set_filenames:
    dec si
    call parse_files

op_exit_sucess:
    xor ax, ax
    
op_exit:

    pop ds

    ret
option_parse endp

end

; OPTION.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to WC. This work is published 
; from: United States.

.186
.model small

.data?

; list of file names. each file name is null terminated. 
; DOS command line is limited to 127 characters. 
public file_list
file_list db 258 dup(?)

.data

public _opt_c, _opt_h, _opt_l, _opt_w

; error message
bad_arg db "Invalid option '"
bad_op db " '", 0dh, 0ah, "use -h for help$"

_opt_c db 0
_opt_h db 0
_opt_l db 0
_opt_w db 0

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
    jz op_exit_done
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

    cmp al, 'c'
    jnz op_h
    mov byte ptr es:[_opt_c], 1
    jmp op_switch_end

op_h:
    cmp al, 'h'
    jnz op_l
    mov byte ptr es:[_opt_h], 1
    jmp op_switch_end

op_l:
    cmp al, 'l'
    jnz op_w
    mov byte ptr es:[_opt_l], 1
    jmp op_switch_end

op_w:
    cmp al, 'w'
    jnz op_badarg
    mov byte ptr es:[_opt_w], 1

op_switch_end:
    mov al, byte ptr ds:[si]
    cmp al, 0dh
    jz op_exit_done
    cmp al, ' '
    jz op_skip_space
    jmp op_next_arg
    
op_set_filenames:
    dec si
    call parse_files

op_exit_done:
    ; if no options are set, set them all
    cmp es:[_opt_h], 1
    je op_exit_success
    cmp es:[_opt_c], 1
    je op_exit_success
    cmp es:[_opt_l], 1
    je op_exit_success
    cmp es:[_opt_w], 1 
    je op_exit_success

    mov es:[_opt_c], 1
    mov es:[_opt_l], 1
    mov es:[_opt_w], 1

op_exit_success:
    xor ax, ax
    
op_exit:

    pop ds

    ret
option_parse endp

end

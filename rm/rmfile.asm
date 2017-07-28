; RMFILE.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

include io.inc

.data

extrn _opt_i:byte
extrn lf:byte
file_exists db ' file exists. Remove Y/N: ', 0
error_remove db 'Unable to remove file ', 0

.code

extrn puts:near

; ds:si file to remove
public rmfile 
rmfile proc

    mov di, si

    cmp byte ptr [_opt_i], 0
    jz rmfile_clobber

rmfile_prompt:

    mov si, di
    call puts 
    lea si, file_exists
    call puts
    lea si, lf
    call puts

    ; get character
    mov ah, 01h
    int 21h
    push ax
    lea si, lf
    call puts
    pop ax
    cmp al, 'N'
    jz rmfile_exit_success
    cmp al, 'n'
    jz rmfile_exit_success
    cmp al, 'Y'
    jz rmfile_clobber 
    cmp al, 'y'
    jnz rmfile_prompt

rmfile_clobber:

    ; delete file
    mov ah, 041h
    mov dx, di
    int 21h
    jnc rmfile_exit_success

    push ax
    lea si, error_remove 
    call puts
    mov si, di
    call puts
    lea si, lf
    call puts
    pop ax
    ; ax = error code
    jmp rmfile_exit

rmfile_exit_success:
    xor ax, ax

rmfile_exit:

    ret
rmfile endp

end

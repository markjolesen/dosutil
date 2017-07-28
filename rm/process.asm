; PROCESS.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to RM. This work is published 
; from: United States.

.186
.model small

include io.inc

DTA_ARRAY_SIZE EQU 512

.data?

dta_array disk_transfer_area DTA_ARRAY_SIZE dup(?)
dir_target_path db 128 dup(?)
file_source db 128 dup(?)

.data

extrn _opt_uR:byte

public lf

error_remove_subdir db 'Unable to remove subdirectory ', 0

lf db 0dh, 0ah, 0

.code

extrn puts:near
extrn path_push:near, path_pop:near
extrn rmfile:near

; ds:si file to process
public process 
process proc

    push bp 
    mov bp, sp 
    sub sp, 04h
    ; [bp - 2] dta slot
    ; [bp - 4] dta pointer
    mov word ptr [bp - 2], 0

    mov byte ptr [dir_target_path], 0

process_dta_set:

    ; set dta
    mov ax, size disk_transfer_area 
    mov bx, word ptr [bp - 2]
    mul bx
    lea dx, dta_array
    add dx, ax
    mov ah, 1ah
    int 21h
    mov word ptr [bp - 4], dx

    ; find first file
    mov cx, 111111b
    mov dx, si
    mov ah, 04eh
    int 21h
    jc process_pop

process_start:

    ; ignore '.' and '..'
    mov si, word ptr [bp - 4]
    lea si, [si].dta_name
    lodsb
    cmp al, '.'
    jnz process_check_type
    lodsb
    or al, al
    jz process_findnext
    cmp al, '.'
    jnz process_check_type
    lodsb
    or al, al
    jz process_findnext

process_check_type:

    mov si, word ptr [bp - 4]
    mov al, byte ptr [si].dta_attr
    test al, FILE_SUBDIRECTORY
    jnz process_subdir

    lea si, dir_target_path
    lea di, file_source
    mov byte ptr [di], 0
    cmp byte ptr [si], 0
    jz process_copy_skip
process_copy_target1:
    lodsb
    stosb
    or al, al
    jnz process_copy_target1
    mov byte ptr [di-1], '\'
process_copy_skip:
    mov si, word ptr [bp - 4]
    lea si, [si].dta_name
process_copy_name:
    lodsb
    stosb
    or al, al
    jnz process_copy_name
    lea si, file_source
    call rmfile
    jmp process_findnext

process_subdir:

    lea di, [si].dta_name
    lea si, dir_target_path
    call path_push
    cmp [_opt_uR], 0
    jnz process_clobber

    lea si, error_remove_subdir
    call puts
    lea si, dir_target_path
    call puts
    lea si, lf
    call puts
    jmp process_exit

process_clobber:
    lea di, file_source

process_copy_target2:
    lodsb
    stosb
    or al, al
    jnz process_copy_target2
    mov byte ptr [di-1], '\'
    mov byte ptr [di+0], '*'
    mov byte ptr [di+1], '.'
    mov byte ptr [di+2], '*'
    mov byte ptr [di+3], 0
    mov ax, word ptr [bp - 2]
    inc ax
    cmp ax, DTA_ARRAY_SIZE
    jge process_exit ; buffer overflow
    mov word ptr [bp - 2], ax
    lea si, file_source
    jmp process_dta_set

process_findnext:

    ; find next file
    mov ah, 04fh
    int 21h
    jnc process_start

process_pop:

    mov ax, word ptr [bp - 2]
    or ax, ax
    jz process_exit
    dec ax
    mov word ptr [bp - 2], ax

    ; remove subdirectory
    mov ah, 03ah
    lea dx, dir_target_path
    int 21h
    jnc process_pop_path

    lea si, error_remove_subdir
    call puts
    lea si, dir_target_path
    call puts
    lea si, lf
    call puts

process_pop_path:

    lea si, dir_target_path
    call path_pop

    ; set dta
    mov ax, size disk_transfer_area 
    mov bx, word ptr [bp - 2]
    mul bx
    lea dx, dta_array
    add dx, ax
    mov ah, 1ah
    int 21h
    mov word ptr [bp - 4], dx
    jmp process_findnext

process_exit:

    mov sp, bp
    pop bp 

    ret
process endp

end

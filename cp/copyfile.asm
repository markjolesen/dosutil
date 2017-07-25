; COPYFILE.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CP. This work is published 
; from: United States.

.186
.model small

include io.inc

BUFFER_SIZE equ 512

.data?

buffer db BUFFER_SIZE dup(?)
file_source db 128 dup(?)
file_target db 128 dup(?)

.data

extrn _opt_i:byte, _opt_p:byte
extrn lf:byte

public identical_files, unable_to_convert_path, open_error

file_exists db ' file exists. Overwrite Y/N: ', 0
open_error db 'Unable to open ', 0
read_error db 'Unable to read from file ', 0
write_error db 'Unable to write to file ', 0
settime_error db 'Unable to set time ', 0
identical_files db 'Files are identical ', 0
unable_to_convert_path db 'Unable to convert path ', 0

.code

extrn sl_strcmp:near
extrn puts:near

; copies a file to another file
; inputs:
;   ds:si source file
;   ds:di target file
; outputs:
;   ax 0 success
;   ax -1 failure
; destroys:
;   ax
public copyfile
copyfile proc

    push bx
    push cx
    push dx
    push si
    push di
    
    push bp 
    mov bp, sp 
    sub sp, 08h
    ; [bp - 2] source file handle
    ; [bp - 4] target file handle
    ; [bp - 6] source file
    ; [bp - 8] target file
    mov word ptr [bp - 2], -1
    mov word ptr [bp - 4], -1
    mov word ptr [bp - 6], si
    mov word ptr [bp - 8], di

    ; convert source to full path
    lea di, file_source
    mov ah, 060h
    int 21h
    jnc copyfile_convert_target

    lea si, unable_to_convert_path
    call puts
    mov si, word ptr [bp - 6]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_convert_target:
    ; convert target to full path
    mov si, word ptr [bp - 8]
    lea di, file_target
    mov ah, 060h
    int 21h
    jnc copyfile_compare

    lea si, unable_to_convert_path
    call puts
    mov si, word ptr [bp - 8]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_compare:

    ; compare file names
    lea di, file_source
    lea si, file_target
    mov dx, ds
    call sl_strcmp
    jne copyfile_check_clobber

    lea si, identical_files
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_check_clobber:

    cmp byte ptr [_opt_i], 0
    jz copyfile_clobber
    
    ; check if target file exists
    mov ah, 03dh
    xor al, al ; read only
    lea dx, file_target ; target file
    int 21h
    jc copyfile_clobber
    
    ; close file
    mov bx, ax
    mov ah, 03eh
    int 21h
    
copyfile_prompt:
    mov si, word ptr [bp - 8]
    call puts
    lea si, file_exists
    call puts
    ; get character
    mov ah, 01h
    int 21h
    push ax
    lea si, lf
    call puts
    pop ax
    cmp al, 'N'
    jz copyfile_exit_success
    cmp al, 'n'
    jz copyfile_exit_success
    cmp al, 'Y'
    jz copyfile_clobber 
    cmp al, 'y'
    jnz copyfile_prompt
    
copyfile_clobber:
    mov ah, 03dh
    xor al, al ; read only
    lea dx, file_source
    int 21h
    jnc copyfile_create_target

    lea si, open_error
    call puts
    mov si, word ptr [bp - 6]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit
 
copyfile_create_target:
    mov word ptr [bp - 2], ax

    ; create or truncate target file
    mov ah, 03ch
    mov cx, FILE_ARCHIVE
    lea dx, file_target
    int 21h
    jnc copyfile_start

    lea si, open_error
    call puts
    mov si, word ptr [bp - 8]
    call puts
    lea si, lf
    call puts
    mov ax, -1 
    jmp copyfile_exit

copyfile_start:
    mov word ptr [bp - 4], ax
    
copyfile_next:

    ; read from source
    mov ah, 3fh
    mov bx, word ptr [bp - 2]
    mov cx, BUFFER_SIZE
    lea dx, buffer
    int 21h
    jc copyfile_read_error
    or ax, ax
    jz copyfile_exit_success

    ; write to target
    mov cx, ax
    mov bx, word ptr [bp - 4]
    mov ah, 40h
    int 21h
    jc copyfile_write_error
    jmp copyfile_next

copyfile_read_error:
    lea si, read_error
    call puts
    mov si, word ptr [bp - 6]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_write_error:
    lea si, write_error
    call puts
    mov si, word ptr [bp - 8]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_exit_success:
    cmp byte ptr [_opt_p], 0
    jz copyfile_skip_settime

    ; get stamp
    mov ah, 057h
    xor al, al 
    mov bx, word ptr [bp - 2]
    int 21h
    jc copyfile_settime_error

    ; set stamp
    mov ah, 057h
    mov al, 1 ; set date time
    mov bx, word ptr [bp - 4]
    int 21h
    jnc copyfile_skip_settime

copyfile_settime_error:
    lea si, settime_error
    call puts
    mov si, word ptr [bp - 8]
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp copyfile_exit

copyfile_skip_settime:
    xor ax, ax
    
copyfile_exit:
    mov bx, word ptr [bp - 2]
    cmp bx, -1
    je copyfile_close_target
    push ax
    mov ah, 03eh
    int 21h
    pop ax

copyfile_close_target:
    mov bx, word ptr [bp - 4]
    cmp bx, -1
    je copyfile_finished
    push ax
    mov ah, 03eh
    int 21h
    pop ax

copyfile_finished:
    
    mov sp, bp
    pop bp 
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
copyfile endp

end

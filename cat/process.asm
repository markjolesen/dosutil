; PROCESS.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to WC. This work is published 
; from: United States.

.186
.model small

include io.inc

BUFFER_SIZE equ 512

.data?

public buffer
buffer db BUFFER_SIZE dup(?)

.data

extrn dta:disk_transfer_area
public _buffer_size

_buffer_size dw BUFFER_SIZE

access_error db 'Unable to access ', 0
invalid_error db 'Invalid file type ', 0
lf db 0dh, 0ah, 0

.code

extrn puts:near

; process 
; ax file handle
public process
process proc

    push bx
    push cx
    push dx
    push si
    push di

    mov bx, ax ; file handle

    ; read from file
    ; ah 3fh
    ; bx file handle
    ; cx number of bytes
    ; ds:dx buffer
    ; returns
    ; ax number of bytes read if cf not set
    ; ax error code if cf set

process_read_chunk:
    mov cx, word ptr [_buffer_size]
    lea dx, buffer
    mov ah, 03fh
    int 21h
    jc process_error
    or ax, ax
    jz process_exit

    ; write to file
    ; ah 40h
    ; bx file handle
    ; cx number of bytes to write
    ; ds:dx buffer
    ; returns
    ; ax number of bytes read if cf not set
    ; ax error code if cf set
    push bx
    mov bx, 1 ; stdout
    mov cx, ax
    mov ah, 040h
    int 21h
    pop bx
    jc process_error
    jmp process_read_chunk

process_error:

process_exit:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    
    ret
process endp

; process file in dta
process_dta proc

    push bx
    push cx
    push dx
    push si

    lea si, dta
    mov al, byte ptr [si].dta_attr
    and al, (FILE_VOLUME_LABEL or FILE_SUBDIRECTORY)
    jz process_dta_open

    add si, offset dta_name
    cmp byte ptr [si], '.'
    jz process_dta_exit

    lea si, invalid_error
    call puts
    lea si, dta.dta_name
    call puts
    lea si, lf
    call puts
    jmp process_dta_exit

process_dta_open:
    ; open file 
    ; ah 3dh
    ; al 
    ;  00 read only
    ;  01 write only
    ;  02 readd/write
    ; ds:dx ASCIZ file spec
    ; ax = file handle if cf not set
    ; ax = error code if cf set
    mov ah, 03dh 
    mov al, 0 
    lea dx, dta.dta_name
    int 21h
    jnc process_dta_start

    lea si, access_error
    call puts
    mov si, dx
    call puts
    lea si, lf
    call puts
    jmp process_dta_exit

process_dta_start:
    call process

    ; close file
    ; ah 3e
    ; bx file handle
    mov ah, 03eh
    mov bx, ax
    int 21h

process_dta_exit:

    pop si
    pop dx
    pop cx
    pop bx
    ret

process_dta endp

; process a file
; ds:ax file name
public process_file
process_file proc

    push bx
    push cx
    push dx
    push si

	; check for stdin '-'
	mov si, ax
	cmp byte ptr [si], '-'
	jne process_file_start
	cmp byte ptr [si+1], 0
	jne process_file_start

	xor ax, ax
	call process
	jmp process_file_exit

process_file_start:

    ; Find first file
    ; ah 4eh
    ; al unused
    ; cx file attributes
    ;   bit(s)
    ;   0 read-only
    ;   1 hidden
    ;   2 system
    ;   3 volume label
    ;   4 directory
    ;   5 archive
    ;   6-15 reserved
    ; ds:dx ASCIZ file spec
    mov cx, 111111b
    mov dx, ax
    mov ah, 04eh
    int 21h
    jc process_file_error

process_file_next:
    call process_dta
    ; Find next matching file
    mov ah, 04fh
    int 21h
    jnc process_file_next

    ; check for error
    jmp process_file_exit

process_file_error:
    lea si, access_error
    call puts
    mov si, dx
    call puts
    lea si, lf
    call puts
    mov ax, -1

process_file_exit:

    pop si
    pop dx
    pop cx
    pop bx

    ret
process_file endp

end

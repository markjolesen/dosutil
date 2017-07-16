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
public lf

access_error db 'Unable to access ', 0
invalid_error db 'Invalid file type ', 0
lf db 0dh, 0ah, 0

public bytes, lines, words

bytes dd 0
lines dd 0
words dd 0

public total_bytes, total_lines, total_words

total_bytes dd 0
total_lines dd 0
total_words dd 0

.code

extrn print_count:near
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
    mov di, 1 ; space indicator on
    mov word ptr [bytes], 0
    mov word ptr [bytes+2], 0
    mov word ptr [lines], 0
    mov word ptr [lines+2], 0
    mov word ptr [words], 0
    mov word ptr [words+2], 0

    ; read from file
    ; ah 3fh
    ; bx file handle
    ; cx number of bytes
    ; ds:dx buffer
    ; returns
    ; ax number of bytes read if cf not set
    ; ax error code if cf set

process_read_chunk:
    mov cx, BUFFER_SIZE
    lea dx, buffer
    mov ah, 03fh
    int 21h
    jc process_error
    or ax, ax
    jz process_exit

    mov si, dx
    mov cx, ax

    add word ptr [bytes], ax
    adc word ptr [bytes+2], 0

process_next_byte:
    
    lodsb
    cmp al, 0ah ; new line
    jne process_switch
    add word ptr [lines], 1
    adc word ptr [lines+2], 0
    jmp proccess_switch_is_space

process_switch:
    ; check if a space 
    cmp al, 020h  ; space 
    je proccess_switch_is_space
    cmp al, 09h ; horizontal tab 
    je proccess_switch_is_space
    cmp al, 0dh ; carriage return 
    je proccess_switch_is_space
    cmp al, 0bh ; vertical tab 
    je proccess_switch_is_space
    cmp al, 0ch ; feed 
    je proccess_switch_is_space

    cmp di, 1
    jne process_switch_end
    mov di, 0 ; indicate space flag off and increment word count
    add word ptr [words], 1
    adc word ptr [words+2], 0

    jmp process_switch_end
    
proccess_switch_is_space:

    mov di, 1 ; indicate space flag on

process_switch_end:

    dec cx
    jz process_read_chunk
    jmp process_next_byte

process_error:

process_exit:

    ; total bytes
    mov ax, word ptr [bytes]
    mov dx, word ptr [bytes+2] 
    mov bx, word ptr [total_bytes] 
    add bx, ax 
    mov ax, word ptr [total_bytes+2] 
    adc ax, dx 
    mov word ptr [total_bytes], bx
    mov word ptr [total_bytes+2], ax

    ; total lines
    mov ax, word ptr [lines]
    mov dx, word ptr [lines+2] 
    mov bx, word ptr [total_lines] 
    add bx, ax 
    mov ax, word ptr [total_lines+2] 
    adc ax, dx 
    mov word ptr [total_lines], bx
    mov word ptr [total_lines+2], ax

    ; total words
    mov ax, word ptr [words]
    mov dx, word ptr [words+2] 
    mov bx, word ptr [total_words] 
    add bx, ax 
    mov ax, word ptr [total_words+2] 
    adc ax, dx 
    mov word ptr [total_words], bx
    mov word ptr [total_words+2], ax

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    call print_count

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
    call print_count
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

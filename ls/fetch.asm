; FETCH.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.data

extrn lf:byte

access_error db 'Unable to access ', 0

.code

extrn filebuf_append:near
extrn puts:near

; fetches files and pushes them onto filebuf (buffer)
; inputs:
;   dta area set
;   ds:ax path to fetch
; outputs:
;   ax 0 success
;   ax -1 failure
; destroys:
;   ax
public fetch_dir
fetch_dir proc

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
    jc fd_error 
    call filebuf_append
    
    ; Find next matching file
fd_next_file:
    mov ah, 04fh
    int 21h
    jc fd_check_error 
    call filebuf_append
    or ax, ax
    jz fd_next_file
    
    ; out of memory
    jmp fd_exit
    
fd_check_error:
    xor ax, ax
    jmp fd_exit

fd_error:
    lea si, access_error
    call puts
    mov si, dx
    call puts
    lea si, lf
    call puts
    mov ax, -1

fd_exit:

    pop si
    pop dx
    pop cx

    ret
fetch_dir endp

end

; DIRBUF.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

include io.inc

.data

extrn buffer_slot:word, buffer:word

public dirbuf, dirbuf_slot

dirbuf_slot dw 0 ; current slot
dirbuf_buckets dw 0 ; size of array. total number of buckets
dirbuf dw 0 ; segment of dirbuf array
dirbuf_alloc_error db 'Unable to allocate directory buffer', 0dh, 0ah, 0

.code

extrn puts:near

; initialize dirbuf
; inputs:
;  none
; outputs:
;  ax 0 sucess
;  ax !0 failure
; destroys:
;  ax, bx, si
;
public dirbuf_init 
dirbuf_init proc

    mov word ptr [dirbuf_slot], 0

    ; allocate 512 filename structs
    ; (512 * 13) >> 4 = 416 paras = 6656 bytes
    mov bx, 1a0h
    mov ah, 048h
    int 21h
    jc  dirbuf_init_alloc_error
    mov word ptr [dirbuf], ax
    mov word ptr [dirbuf_buckets], 512
    xor ax, ax
    jmp dirbuf_init_exit
    
dirbuf_init_alloc_error:
    lea si, dirbuf_alloc_error
    call puts
    mov ax, -1

dirbuf_init_exit:

    ret
dirbuf_init endp

; deinitialize dirbuf
; inputs:
;  none
; outputs:
;  none
; destroys:
;  none
public dirbuf_deinit
dirbuf_deinit proc

    push ax
    push es

    mov ax, word ptr [dirbuf]
    or ax, ax
    jz dirbuf_deinit_exit
    
    ; free memory
    mov es, ax
    mov ah, 049h
    int 21h
    
dirbuf_deinit_exit:

    pop es
    pop ax

    ret
dirbuf_deinit endp

; pushes directories from filebuf (buffer) to dirbuf
;
; inputs:
;   buffer_slot number of slots in buffer
;   buffer buffer segment 
; outputs:
;   ax number of entries added
; destorys:
;   none
;
public dirbuf_scan_and_push_filebuf 
dirbuf_scan_and_push_filebuf proc

    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    push bp 
    mov bp, sp 
    sub sp, 04h
    ; [bp-2] buffer_slot
    ; [bp-4] dirbuf_slot
    
    mov ax, word ptr [dirbuf_slot]
    mov word ptr [bp-4]], ax

    mov cx, word ptr [buffer_slot]
    or cx, cx
    jz dirbuf_scan_and_push_filebuf_exit
    mov word ptr [bp-2], cx
    
    ; es:di = dirbuf
    mov ax, word ptr [dirbuf]
    mov es, ax
    mov ax, size filename
    mov bx, word ptr [dirbuf_slot]
    cmp bx, 512
    jge dirbuf_scan_and_push_filebuf_overflow
    mul bx
    mov di, ax
    
    ; ds:si last buffer
    mov ax, cx
    dec ax
    mov bx, size file_info
    mul bx
    mov si, ax
    mov ax, word ptr [buffer]
    mov ds, ax
    
dirbuf_scan_and_push_filebuf_next:
    mov al, byte ptr [si].fi_attr
    and al, FILE_SUBDIRECTORY
    jz dirbuf_scan_and_push_filebuf_skip

    push si
    add si, offset fi_name
    mov cx, size filename
    rep movsb
    pop si
    
    mov ax, word ptr [bp-4]
    inc ax
    cmp ax, 512
    jge dirbuf_scan_and_push_filebuf_overflow
    mov word ptr [bp-4], ax
    
dirbuf_scan_and_push_filebuf_skip:
    sub si, size file_info
    mov ax, word ptr [bp-2]
    dec ax
    jz dirbuf_scan_and_push_filebuf_exit
    mov word ptr [bp-2], ax
    jmp dirbuf_scan_and_push_filebuf_next   
    
dirbuf_scan_and_push_filebuf_overflow:

dirbuf_scan_and_push_filebuf_exit:

    mov ax, word ptr [bp-4]

    mov sp, bp
    pop bp 
    
    pop es
    pop ds
    mov bx, word ptr [dirbuf_slot]
    mov word ptr [dirbuf_slot], ax
    sub ax, bx
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
dirbuf_scan_and_push_filebuf endp

end

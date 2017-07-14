; FILEBUF.ASM
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

extrn _opt_a:byte, _opt_uS:byte, _opt_t:byte, _opt_r:byte
extrn dta:disk_transfer_area

public buffer_slot, buffer

buffer_slot dw 0 ; number of occupied slots
buffer_buckets dw 0 ; total number of allocated slots
buffer dw 0 ; buffer segment array of file_info
buffer_overflow db 'File buffer stack full', 0dh, 0ah, 0

.code

extrn compare_size_:near, compare_time_:near
extrn qsort_:near, sl_strcmp:near, puts:near


filebuf_alloc proc

    push ax
    push bx
    push es

    ; each file_info struc will reuire 2 paragraphs of allocation

    mov ax, word ptr [buffer_buckets]
    or ax, ax
    jnz filebuf_alloc_grow
    
    ; allocate 512 file info structs:
    ; (512 * 32) >> 4 = 400h paras = 16384 bytes
    mov bx, 400h
    mov ah, 048h
    int 21h
    jc  filebuf_alloc_error
    mov word ptr [buffer], ax
    mov word ptr [buffer_buckets], 512
    xor ax, ax
    jmp filebuf_alloc_exit

filebuf_alloc_grow:
    add ax, 512
    cmp ax, 2048
    jge filebuf_alloc_error
    mov bx, 32
    mul bx
    shr ax, 4
    ; modify allocated memory
    mov bx, ax
    mov ax, word ptr [buffer]
    mov es, ax
    mov ah, 04ah
    int 21h
    jc filebuf_alloc_error
    mov ax, word ptr [buffer_buckets]
    add ax, 512
    mov word ptr [buffer_buckets], ax
    xor ax, ax
    jmp filebuf_alloc_exit
    
filebuf_alloc_error:
    mov ax, -1    
    
filebuf_alloc_exit:

    pop es
    pop bx
    pop ax
    
    ret
filebuf_alloc endp

public filebuf_init
filebuf_init proc
    mov word ptr [buffer_slot], 0
    mov word ptr [buffer_buckets], 0
    mov word ptr [buffer], 0
    ret
filebuf_init endp

public filebuf_deinit
filebuf_deinit proc

    push es
    push ax

    mov ax, word ptr [buffer]
    or ax, ax
    jz filebuf_deinit_exit
    ; free memory
    mov es, ax
    mov ah, 049h
    int 21h
    
filebuf_deinit_exit:
    mov word ptr [buffer_slot], 0
    mov word ptr [buffer_buckets], 0
    mov word ptr [buffer], 0

    pop ax
    pop es
    
    ret
filebuf_deinit endp

; push current dta onto file buffer stack
; inputs: 
;   dta valid (loaded with file info)
;   es = ds = dgroup
; outputs:
;   buffer_slot on success incremented
;   buffer dta copied on success
;   ax 0 success
;   ax -1 failure (not enough memory)
; destroys
;  ax
public filebuf_append  
filebuf_append proc

    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    
    ; ignore hidden filees unless _opt_a is set
    xor ax, ax
    mov al, byte ptr [dta.dta_attr]
    and al, FILE_HIDDEN
    jz filebuf_append_check_dot
    cmp byte ptr [_opt_a], 0
    jz filebuf_append_exit
    
filebuf_append_check_dot:
    xor ax, ax,
    ; ignore '.' and '..'
    lea si, dta.dta_name
    lodsb
    cmp al, '.'
    jnz filebuf_append_start
    lodsb
    or al, al
    jz filebuf_append_exit
    cmp al, '.'
    jnz filebuf_append_start
    lodsb
    or al, al
    jz filebuf_append_exit
    
filebuf_append_start:
    mov ax, word ptr [buffer_buckets]
    cmp ax, word ptr [buffer_slot]
    jnz filebuf_append_check
    call filebuf_alloc 
    cmp ax, -1
    jz filebuf_append_error

filebuf_append_check:
    ; check if top of stack reached
    mov ax, word ptr [buffer_slot]
    cmp ax, word ptr [buffer_buckets]
    jge filebuf_append_error
    
    ; set es:di to point to indexed slot
    mov bx, size file_info 
    mul bx
    mov di, ax
    mov ax, word ptr [buffer]
    mov es, ax
    
    ; copy dta into buffer
    push di
    lea si, dta.dta_attr
    mov cx, size file_info
    rep movsb
    pop di
    
    ; convert file name to upper case
    lea di, [di].fi_name
    mov si, di
    push ds
    push es
    pop ds
    jmp filebuf_append_ucase_next
    
filebuf_append_ucase:
    stosb
filebuf_append_ucase_next:
    lodsb
    xor al, al
    jz filebuf_append_done
    cmp al, 'a'
    jb filebuf_append_ucase
    cmp al, 'z'
    ja filebuf_append_ucase
    sub al, 'Z'
    jmp filebuf_append_ucase
    
filebuf_append_done:    
    pop ds
    inc word ptr [buffer_slot]
    xor ax, ax
    jmp filebuf_append_exit
    
filebuf_append_error:
    lea si, buffer_overflow
    call puts
    mov ax, -1
    
filebuf_append_exit:

    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
filebuf_append endp

; places a file buffer at a given index into the dta
; inputs:
;   ax slot to retrieve
;   es = ds = dgroup
; outputs:
;  ax 0 success
;  ax -1 failure (slot out of bounds)
; destroys:
;  ax
;
public filebuf_get
filebuf_get proc

    push bx
    push cx
    push dx
    push si
    push di
    push ds
    
    cmp ax, word ptr [buffer_slot]
    jge filebuf_get_error
    
   ; set ds:si file_info
    mov bx, size file_info
    mul ax
    mov si, word ptr [buffer]
    mov ds, si
    mov si, ax
    
    lea di, dta.dta_attr
    mov cx, size file_info
    rep movsb
    xor ax, ax
    jmp filebuf_get_exit
    
filebuf_get_error:
    mov ax, -1
    
filebuf_get_exit:

    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    
    ret
filebuf_get endp

; inputs:
;  dx:ax filebuf to compare
;  cx:bx filebuf to compare against
public filebuf_compare_fn_
filebuf_compare_fn_ proc

    push si
    push di
    push es

    ;es:di-First string (The string to compare)
    ;dx:si-Second string (The string to compare against)
    mov di, ax
    add di, offset fi_name
    mov es, dx
    mov si, bx
    add si, offset fi_name
    mov dx, cx
    mov bl, byte ptr [_opt_r]
    call sl_strcmp
    jb filebuf_compare_fn_less
    ja filebuf_compare_fn_greater
    
    xor ax, ax 
    jmp filebuf_compare_fn_exit

filebuf_compare_fn_greater:
    or bl, bl
    jz filebuf_compare_fn_greater_asc
    mov ax, -1
    jmp filebuf_compare_fn_exit
    
filebuf_compare_fn_greater_asc:
    mov ax, 1
    jmp filebuf_compare_fn_exit
    
filebuf_compare_fn_less:
    or bl, bl
    jz filebuf_compare_fn_less_asc
    mov ax, 1
    jmp filebuf_compare_fn_exit 
    
filebuf_compare_fn_less_asc:
    mov ax, -1
    jmp filebuf_compare_fn_exit 

filebuf_compare_fn_exit:

    pop es
    pop di
    pop si

    cld
    
    ret
filebuf_compare_fn_ endp

public filebuf_sort
filebuf_sort proc

    push ax
    push bx
    push cx
    push dx
    push es
    
    ; qsort(void __far *a, size_t n, size_t es, cmp_t *cmp)
    ; bp+4 <- cmp
    ; bx <- es
    ; cx <- n
    ; dx:ax <- a
    cmp byte ptr [_opt_uS], 0
    jz filebuf_sort_time
    
    mov ax, offset compare_size_
    jmp filebuf_sort_start
    
filebuf_sort_time:
    cmp byte ptr [_opt_t], 0
    jz filebuf_sort_default
    
    mov ax, offset compare_time_
    jmp filebuf_sort_start
    
filebuf_sort_default:
    mov ax, offset filebuf_compare_fn_
    
filebuf_sort_start:    
    push ax
    mov cx, size file_info
    mov bx, word ptr [buffer_slot]
    mov dx, word ptr [buffer]
    xor ax, ax
    call qsort_
    mov dx, word ptr [buffer]
    
    pop es
    pop dx
    pop cx
    pop bx
    pop ax

    ret
filebuf_sort endp

end

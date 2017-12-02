; PROCESS.ASM
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

extrn _opt_uC:byte, _opt_uR:byte, _opt_f:byte, _opt_1:byte, _opt_m:byte
extrn _opt_x:byte

extrn dirbuf:word, dirbuf_slot:word
extrn buffer:word, buffer_slot:word
extrn dta:disk_transfer_area
extrn lf:byte
extern scratch:byte
extrn path:byte

.code

extrn sl_itoa:near, sl_ltoa:near
extrn filebuf_sort:near, filebuf_get:near
extrn puts:near
extrn dirbuf_scan_and_push_filebuf:near
extrn path_push:near, path_pop:near
extrn fetch_dir:near
extrn print_attributes:near, print_size:near, print_date:near
extrn print_time:near, print_file:near
    
; print file list in comma separated format (_opt_m)
process_csv proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    
    mov bx, word ptr [buffer_slot]
    mov ax, word ptr [buffer]
    mov ds, ax
    mov es, ax
    xor cx, cx ; slot
    xor dx, dx ; bytes written
    
process_csv_next:
    push bx
    push dx
    mov ax, cx
    mov bx, size file_info
    mul bx 
    mov si, ax
    add si, offset fi_name
    pop dx
    pop bx
    
    ; strlen
    push cx
    mov di, si
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx
    mov di, cx
    mov ax, dx
    add dx, cx 
    pop cx

    cmp dx, 78  ; line length limit
    jb process_cvs_comma
    ; print newline
    mov ah, 02h
    mov dl, 0ah
    int 21h
    mov ah, 02h
    mov dl, 0dh
    int 21h
    mov dx, di
    jmp process_cvs_puts
    
process_cvs_comma:
    or ax, ax
    jz process_cvs_puts
    ; print comma and space
    push dx
    mov ah, 02h
    mov dl, ','
    int 21h
    mov ah, 02h
    mov dl, ' '
    int 21h
    pop dx
    inc dx
    inc dx
    
process_cvs_puts:
    call puts
    inc cx
    cmp cx, bx
    jb process_csv_next
    
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    
    push si 
    lea si, lf
    call puts
    pop si
    
    ret
process_csv endp

; print file list in column format (_opt_x)
process_cols proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    push bp 
    mov bp, sp 
    sub sp, 04h
    ; [bp - 2] slot
    ; [bp - 4] column
    mov word ptr [bp - 2], 0
    mov word ptr [bp - 4], 0
    
process_cols_next:
    push ds
    mov ax, word ptr [buffer]
    mov ds, ax
    mov ax, word ptr [bp - 2]
    mov bx, size file_info
    mul bx 
    mov si, ax
    call print_file
    pop ds
    
    ; calculate how much space to write 
    mov bx, ax ; characters written (ret from puts)
    mov ax, 15 ; width of a column
    sub ax, bx
    mov cx, ax
process_cols_write_space:
    mov ah, 02h
    mov dl, ' '
    int 21h
    loop process_cols_write_space
    
    mov ax, word ptr [bp - 4]
    inc ax
    mov word ptr [bp - 4], ax
    cmp ax, 5 ; 5 columns
    jb process_cols_skip_lf
    lea si, lf
    call puts
    mov word ptr [bp - 4], 0
process_cols_skip_lf:
    mov ax, word ptr [bp - 2]
    inc ax
    mov word ptr [bp - 2], ax
    cmp ax, word ptr [buffer_slot]
    jb process_cols_next

    mov sp, bp
    pop bp 
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
process_cols endp

; print file list sorted by columns (_opt_uC)
process_rows proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    push bp 
    mov bp, sp 
    sub sp, 08h
    ; [bp - 2] total number of rows
    ; [bp - 4] row
    ; [bp - 6] column
    ; [bp - 8] index/slot
    
    ; set total number of rows
    ; columns are 15 characters wide 
    ; total of 5 columns
    ; 
    mov ax, word ptr [buffer_slot]
    or ax, ax
    jz process_rows_exit
    cwd
    mov bx, 5
    div bx
    or dx, dx
    jz process_rows_no_fract 
    inc ax 
process_rows_no_fract: 
    mov word ptr [bp - 2], ax ; total rows
    mov word ptr [bp - 4], 0 ; row
    mov word ptr [bp - 6], 0 ; column
    mov word ptr [bp - 8], 0 ; index/slot
    
process_rows_next:
    push ds
    mov ax, word ptr [buffer]
    mov ds, ax
    mov ax, word ptr [bp - 8]
    push dx
    mov bx, size file_info
    mul bx 
    pop dx
    mov si, ax
    call print_file
    pop ds
    
    ; calculate how much space to write 
    mov bx, ax ; characters written (ret from puts)
    mov ax, 15 ; width of a column
    sub ax, bx
    mov cx, ax
    
process_rows_write_space:
    mov ah, 02h
    mov dl, ' '
    int 21h
    loop process_rows_write_space
    
    ; check column count
    mov ax, word ptr [bp - 6] ; column
    inc ax
    cmp ax, 5
    jge process_rows_next_row
    mov word ptr [bp - 6], ax
    mov ax, word ptr [bp - 8] ; index/slot
    mov bx, word ptr [bp - 2] ; total rows
    add ax, bx
    cmp ax, word ptr [buffer_slot]
    jge process_rows_next_row
    mov word ptr [bp - 8], ax
    jmp process_rows_next
    
process_rows_next_row:   
    lea si, lf
    call puts

    ; check row
    mov ax, word ptr [bp - 4] ; row
    inc ax
    cmp ax, word ptr [bp - 2]
    jge process_rows_exit
    mov word ptr [bp - 4], ax
    mov word ptr [bp - 8], ax
    mov word ptr [bp - 6], 0
    jmp process_rows_next
    
process_rows_exit:
    
    mov sp, bp
    pop bp 
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret
process_rows endp

; print file list one item per line 
process_single_line proc

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor cx, cx ; slot
    
process_single_line_next:
    push ds
    mov ax, word ptr [buffer]
    mov ds, ax
    mov ax, cx
    mov bx, size file_info
    mul bx 
    mov si, ax
    mov al, byte ptr es:[_opt_1]
    test al, al
    jnz process_single_line_short
    call print_attributes
    call print_size
    call print_date
    call print_time
    
process_single_line_short:    
    call print_file
    pop ds
    lea si, lf
    call puts
    inc cx
    cmp cx, word ptr [buffer_slot]
    jb process_single_line_next

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

process_single_line endp

; print file list depending upon flags
process_switch proc

    cmp byte ptr [_opt_f], 0
    jnz process_switch_start
    
    call filebuf_sort
    
process_switch_start:
    cmp byte ptr [_opt_x], 0
    jz process_switch_m
    call process_cols
    jmp process_switch_exit
    
process_switch_m:
    cmp byte ptr [_opt_m], 0
    jz process_switch_uC
    call process_csv
    jmp process_switch_exit
    
process_switch_uC:
    cmp byte ptr [_opt_uC], 0
    jz process_switch_1
    call process_rows
    jmp process_switch_exit
    
process_switch_1:
    call process_single_line
    ;jmp process_switch_exit
    
process_switch_exit:

    ret
process_switch endp

; print file list recursively (_opt_R)
process_recurse proc

    push bp 
    mov bp, sp 
    sub sp, 02h
    ; [bp - 2] number of directories
    
    cmp word ptr [buffer_slot], 0
    jz process_recurse_exit
    
    lea si, path
    call puts 
    mov ah, 02h
    mov dl, ':'
    int 21h
    lea si, lf
    call puts

    call process_switch
    lea si, lf
    call puts

    call dirbuf_scan_and_push_filebuf
    or ax, ax ; any new directories added?
    jz process_recurse_exit
    
    mov word ptr [bp-2], ax
    
process_recurse_dir:
    mov ax, word ptr [dirbuf_slot]
    or ax, ax
    jz process_recurse_exit
    dec ax
    mov word ptr [dirbuf_slot], ax
    mov bx, size filename
    mul bx
    mov dx, word ptr [dirbuf]
    call path_push
    mov word ptr [buffer_slot], 0
    
    ; copy path into scratch 
    lea si, path
    lea di, scratch
    cmp byte ptr [si], 0
    jz process_recurse_append_wildcard
    
process_recurse_copy_next:
    lodsb
    stosb
    or al, al
    jnz process_recurse_copy_next
    mov byte ptr [di-1], '\'
    
process_recurse_append_wildcard:
    mov byte ptr [di+0], '*'
    mov byte ptr [di+1], '.'
    mov byte ptr [di+2], '*'
    mov byte ptr [di+3], 0
    
    lea ax, scratch
    call fetch_dir
    or ax, ax
    jnz process_recurse_skip
    call process_recurse
process_recurse_skip:
    call path_pop
    mov ax, word ptr [bp-2]
    dec ax
    jz process_recurse_exit
    mov word ptr [bp-2], ax
    jmp process_recurse_dir
    
process_recurse_exit:

    mov sp, bp
    pop bp 
    
    ret
process_recurse endp

; process file list
public process
process proc

    cmp word ptr [buffer_slot], 0
    jz exit

    cmp byte ptr [_opt_uR], 0
    jnz recurse
    
    call process_switch
    jmp exit
    
recurse:
    call process_recurse
    
exit:

    ret
process endp

end

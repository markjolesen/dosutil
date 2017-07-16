; PRINT.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to WC. This work is published 
; from: United States.

.186
.model small

include io.inc

.data

extrn lf:byte
extrn dta:disk_transfer_area
extrn bytes:dword, lines:dword, words:dword
extrn total_bytes:dword, total_lines:dword, total_words:dword
extrn _opt_c:byte, _opt_l:byte, _opt_w:byte
extrn buffer:byte

public files_printed

total db 'total', 0
files_printed dw 0 

.code

extrn sl_ltoa:near
extrn puts:near

; ds:si null terminated string to print (padded at 13 bytes)
print_pad proc

    push ax
    push cx
    push dx
    push si

    ; strlen
    mov di, si
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx

    mov ax, 10
    sub ax, cx
    mov cx, ax
    or cx, cx
    jz print_pad_data

print_pad_space:
    mov ah, 02h
    mov dl, ' '
    int 21h
    dec cx
    jnz print_pad_space

print_pad_data:
    call puts

    pop si
    pop dx
    pop cx
    pop ax

    ret
print_pad endp

public print_total
print_total proc

    push ax
    push dx
    push si
    push di

    cmp byte ptr [_opt_l], 1
    jne print_total_switch_w

    mov ax, word ptr [total_lines]
    mov dx, word ptr [total_lines+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_total_switch_w:
    cmp byte ptr [_opt_w], 1
    jne print_total_switch_c

    mov ax, word ptr [total_words]
    mov dx, word ptr [total_words+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_total_switch_c:
    cmp byte ptr [_opt_c], 1
    jne print_total_name

    mov ax, word ptr [total_bytes]
    mov dx, word ptr [total_bytes+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_total_name:

    mov ah, 02h
    mov dl, ' '
    int 21h
    lea si, total
    call puts
    lea si, lf
    call puts

    pop di
    pop si
    pop dx
    pop ax

    ret
print_total endp

; print line count data
; lines words bytes file_name
public print_count
print_count proc

    push ax
    push dx
    push si
    push di

    cmp byte ptr [_opt_l], 1
    jne print_count_switch_w

    mov ax, word ptr [lines]
    mov dx, word ptr [lines+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_count_switch_w:
    cmp byte ptr [_opt_w], 1
    jne print_count_switch_c

    mov ax, word ptr [words]
    mov dx, word ptr [words+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_count_switch_c:
    cmp byte ptr [_opt_c], 1
    jne print_count_name

    mov ax, word ptr [bytes]
    mov dx, word ptr [bytes+2]
    lea di, buffer
    call sl_ltoa
    mov si, di
    call print_pad

print_count_name:

    mov ah, 02h
    mov dl, ' '
    int 21h
    lea si, dta.dta_name
    call puts
    lea si, lf
    call puts

    pop di
    pop si
    pop dx
    pop ax

    inc word ptr [files_printed]

    ret
print_count endp

end

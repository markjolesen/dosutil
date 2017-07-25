; COPYDIR.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CP. This work is published 
; from: United States.

.186
.model small

include io.inc

DTA_ARRAY_SIZE EQU 512

.data?

dta_array disk_transfer_area DTA_ARRAY_SIZE dup(?)
dir_source_path db 128 dup(?)
dir_source_file db 128 dup(?)
dir_target_orig db 128 dup(?)
dir_target_path db 128 dup(?)

.data

extrn identical_files:byte
extrn _opt_uR:byte
extrn dta:disk_transfer_area
extrn lf:byte

dta_slot dw 0

.code

extrn path_push:near, path_pop:near
extrn puts:near
extrn copyf2d:near

; copy file to directory
;
; inputs:
;   ds:si dta
;   dir_source_path current path
;
copydir_copyf2d proc

    push bx
    push si
    push di

    mov bx, si

    ; copy source path into source file
    lea si, dir_source_path
    lea di, dir_source_file

copydir_copyf2d_source_nextc:
    lodsb
    stosb
    or al, al
    jnz copydir_copyf2d_source_nextc

    mov byte ptr [di-1], '\'
    mov si, bx 
    lea si, [si].dta_name

copydir_copyf2d_name_nextc:
    lodsb
    stosb
    or al, al
    jnz copydir_copyf2d_name_nextc

    lea si, dir_source_file
    lea di, dir_target_path
    call copyf2d

    pop di
    pop si
    pop bx

    ret

copydir_copyf2d endp


; copy a directory into another directory 
; inputs:
;  ds:si source directory
;  ds:di target directory
public copydir
copydir proc

    push bp 
    mov bp, sp 
    sub sp, 02h
    ; [bp - 2] dta pointer

    mov word ptr [dta_slot], 0

    ; load dir_source_path with source (si)
    push di
    mov di, si
    lea si, dir_source_path
    mov byte ptr [si], 0
    call path_push
    pop di

    ; load dir_target_path with source (di)
    lea si, dir_target_path
    mov byte ptr [si], 0
    call path_push

    ; copy target into dir_target_orig
    lea si, dir_target_path
    lea di, dir_target_orig

copy_dir_target_orig:
    lodsb
    stosb
    or al, al
    jnz copy_dir_target_orig

copydir_dta_set:

    ; set dta
    mov ax, size disk_transfer_area 
    mov bx, word ptr [dta_slot]
    mul bx
    lea dx, dta_array
    add dx, ax
    mov ah, 1ah
    int 21h
    mov word ptr [bp - 2], dx

    ; check if source path contained in target
    lea di, dir_source_path
    lea si, dir_target_orig

copydir_compare:
    lodsb
    or al, al
    jz copydir_file_identical
    cmp byte ptr [di], 0
    jz copydir_source_copy_file
    scasb
    jne copydir_source_copy_file
    jmp copydir_compare

copydir_file_identical:
    lea si, identical_files
    call puts
    lea si, dir_source_path
    call puts
    lea si, lf
    call puts
    jmp copydir_finished

copydir_source_copy_file:

    lea si, dir_source_path
    lea di, dir_source_file

copydir_source_copy_file_next:
    lodsb
    or al, al
    jz copydir_source_copy_file_end
    stosb
    jmp copydir_source_copy_file_next
    
copydir_source_copy_file_end:
    mov byte ptr [di+0], '\'
    mov byte ptr [di+1], '*'
    mov byte ptr [di+2], '.'
    mov byte ptr [di+3], '*'
    mov byte ptr [di+4], 0

    ; find first file
    mov cx, 111111b
    lea dx, dir_source_file
    mov ah, 04eh
    int 21h
    jnc copydir_gotfile
    mov ax, -1
    jmp copydir_exit

    ; find next file
copydir_findnext:
    mov ah, 04fh
    int 21h
    jc copydir_finished

copydir_gotfile:

    ; ignore '.' and '..'
    mov si, word ptr [bp - 2]
    lea si, [si].dta_name
    lodsb
    cmp al, '.'
    jnz copydir_start
    lodsb
    or al, al
    jz copydir_findnext
    cmp al, '.'
    jnz copydir_start
    lodsb
    or al, al
    jz copydir_findnext

copydir_start:

    mov si, word ptr [bp - 2]
    mov al, byte ptr [si].dta_attr
    test al, FILE_SUBDIRECTORY
    jnz copydir_subdir

    call copydir_copyf2d
    jmp copydir_findnext

copydir_subdir:

    lea di, [si].dta_name
    lea si, dir_source_path
    call path_push
    
    lea si, dir_target_path
    call path_push

    ; create subdirectory
    mov ah, 039h
    lea dx, dir_target_path
    int 21h

    inc word ptr [dta_slot]
    jmp copydir_dta_set   

copydir_finished:

    mov ax, word ptr [dta_slot]
    or ax, ax
    jz copydir_exit
    dec ax
    mov word ptr [dta_slot], ax

    lea si, dir_source_path
    call path_pop
    lea si, dir_target_path
    call path_pop

    mov ax, size disk_transfer_area 
    mov bx, word ptr [dta_slot]
    mul bx
    lea dx, dta_array
    add dx, ax
    mov ah, 1ah
    int 21h
    mov word ptr [bp - 2], dx
    jmp copydir_findnext

copydir_exit:

    ; reset original dta
    mov ah, 1ah
    lea dx, dta
    int 21h

    mov sp, bp
    pop bp 


    ret
copydir endp

end

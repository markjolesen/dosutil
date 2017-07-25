; PROCESS.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to CP. This work is published 
; from: United States.

.186
.model small

include io.inc

.data?

source db 128 dup(?)
target db 128 dup(?)
scratch db 128 dup(?)

.data

extrn _opt_i:byte, _opt_uR:byte
extrn dta:disk_transfer_area
extrn file_list:byte, file_last:word, file_count:byte
extrn open_error:byte, identical_files:byte, unable_to_convert_path:byte

public lf

error_recurse_omitted db 'Recurse option not specified', 0
error_create_directory db 'Unable to create directory ', 0
target_is_not_directory db 'Target is not a directory', 0
missing_target_operand db 'Missing target operand', 0
omitting_directory db '; omitting directory ', 0
lf db 0dh, 0ah, 0

target_type db 0

.code

extrn puts:near
extrn sl_strcmp:near
extrn copyfile:near, copyf2d:near, copydir:near

; get file type
; inputs:
;  ds:si source file
; outputs:
;  ax 
;    -1 error
;    0 file does not exist (assumes)
;    FILE_ARCHIVE file exists and is archive file
;    FILE_SUBDIRECTORY file exists and is a subdirectory
process_get_type proc

    push bx
    push cx
    push dx
    push si
    push di

    push bp 
    mov bp, sp 
    sub sp, 02h
    ; [bp - 2] source 
    mov word ptr [bp - 2], si

process_get_type_wild_next:
    lodsb
    or al, al
    jz process_get_type_try_open
    cmp al, '*'
    jz process_get_type_is_wild
    cmp al, '?'
    jnz process_get_type_wild_next

process_get_type_is_wild:
    mov ax, FILE_ARCHIVE
    jmp process_get_type_exit

process_get_type_try_open:
    mov ah, 03dh
    xor al, al
    mov dx, word ptr [bp - 2]
    int 21h
    jc process_get_type_open_failed
    mov bx, ax
    mov ah, 03eh
    int 21h
    mov ax, FILE_ARCHIVE
    jmp process_get_type_exit

process_get_type_open_failed:
    cmp ax, 02h ; file not found
    jz process_get_type_does_not_exist
    cmp ax, 05h ; access denied
    jnz process_get_type_exit_error

    ; deterimine if it is a subdirectory
    mov si, [bp - 2]
    lea di, scratch

process_get_type_copy:
    lodsb
    stosb
    or al, al
    jnz process_get_type_copy

    mov byte ptr [di-1], '\'
    mov byte ptr [di+0], '*'
    mov byte ptr [di+1], '.'
    mov byte ptr [di+2], '*'
    mov byte ptr [di+3], 0
 
    ; find first file
    mov cx, 111111b
    lea dx, scratch
    mov ah, 04eh
    int 21h
    jc process_get_type_does_not_exist

    mov ax, FILE_SUBDIRECTORY
    jmp process_get_type_exit

process_get_type_exit_error:
    mov ax, -1
    jmp process_get_type_exit

process_get_type_does_not_exist:
    xor ax, ax

process_get_type_exit:

    mov sp, bp
    pop bp 

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
process_get_type endp

process_target_mkdir proc

    push ax
    push dx
    push si

    ; create subdirectory
    mov ah, 039h
    lea dx, target
    int 21h
    jnc process_target_mkdir_success

    lea si, error_create_directory
    call puts
    mov si, dx
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_target_mkdir_exit

process_target_mkdir_success:
    mov byte ptr [target_type], FILE_SUBDIRECTORY
    xor ax, ax

process_target_mkdir_exit:

    pop si
    pop dx
    pop ax

    ret
process_target_mkdir endp

; copy last argument into target
process_target_setup proc

    push bx
    push cx
    push dx
    push si
    push di

    ; copy target (last file) into scratch
    mov si, word ptr [file_last]
    lea di, scratch
process_target_setup_nextc:
    lodsb
    or al, al
    jz process_target_setup_end
    stosb
    jmp process_target_setup_nextc

process_target_setup_end:
    mov byte ptr [di], 0
    mov si, word ptr [file_last]
    mov byte ptr [si], 0
    dec byte ptr [file_count]

    ; if target ends with a colon, add a backslash
    lea di, scratch
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    dec di
    cmp byte ptr [di-1], ':'
    jnz process_target_setup_convert
    mov byte ptr [di+0], '\'
    mov byte ptr [di+1], 0

process_target_setup_convert:

    ; convert to full path
    lea si, scratch
    lea di, target
    mov ah, 060h
    int 21h
    jnc process_target_setup_get_type

    lea si, unable_to_convert_path 
    call puts
    lea si, scratch
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_target_setup_exit

process_target_setup_get_type:

    lea si, target
    call process_get_type
    mov word ptr [target_type], ax
    cmp ax, -1
    jnz process_target_setup_exit_success

    lea si, open_error
    call puts
    lea si, target
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_target_setup_exit

process_target_setup_exit_success:
    xor ax, ax

process_target_setup_exit:

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
process_target_setup endp


; check if file expands
; inputs:
;   ds:si source file
; outputs:
;   ax 0 does not expand
;   ax 1 expands into other files
process_does_file_expand proc

    push cx
    push dx
    push si

    ; find first file
    mov cx, 111111b
    mov dx, si
    mov ah, 04eh
    int 21h
    jnc process_does_file_expand_next 

    lea si, open_error
    call puts
    mov si, dx
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_does_file_expaned_exit

process_does_file_expand_next:
    mov ah, 04fh
    int 21h
    jc process_does_file_expand_one
    mov ax, 1
    jmp process_does_file_expaned_exit 

process_does_file_expand_one:
    mov ax, 0

process_does_file_expaned_exit:

    pop si
    pop dx
    pop cx

    ret
process_does_file_expand endp

; ds:si source file
process_source_expand proc

    push bx
    push cx
    push dx
    push si
    push di

    ; copy into scratch
    lea di, scratch
process_source_expand_next:
    lodsb
    stosb
    or al, al
    jnz process_source_expand_next

    lea di, scratch
    xor ax, ax
    xor cx, cx
    not cx
    repne scasb
    not cx
    dec cx
    dec di

    cmp cx, 1
    je process_source_expand_switch

    cmp cx, 3
    jb process_source_expand_full

    cmp byte ptr [di-2], ':'
    jz process_source_expand_switch
    cmp byte ptr [di-2], '\'
    jnz process_source_expand_full

process_source_expand_switch:
    cmp byte ptr [di-1], '.'
    jnz process_source_expand_switch_asterik
    mov byte ptr [di-1], '*' 
    mov byte ptr [di+0], '.' 
    mov byte ptr [di+1], '*' 
    mov byte ptr [di+2], 0
    jmp process_source_expand_full

process_source_expand_switch_asterik:
    cmp byte ptr [di-1], '*'
    jnz process_source_expand_full
    mov byte ptr [di+0], '.' 
    mov byte ptr [di+1], '*' 
    mov byte ptr [di+2], 0

process_source_expand_full:

    ; convert to full path
    lea si, scratch
    lea di, source
    mov ah, 060h
    int 21h
    jnc process_source_expand_exit_success

    lea si, unable_to_convert_path 
    call puts
    lea si, scratch
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_source_expand_exit

process_source_expand_exit_success:
    xor ax, ax

process_source_expand_exit:

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
process_source_expand endp

; copy directory to directory
; inputs:
;  source source directory
;  target target directory
process_dir proc

    push cx
    push si
    push di

    cmp [_opt_uR], 1
    jz process_dir_check

    lea si, error_recurse_omitted
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_dir_exit

process_dir_check:

    ; target must be a subdirectory
    cmp [target_type], FILE_SUBDIRECTORY
    jz process_dir_copy

    cmp [target_type], 0
    jz process_dir_create 

    lea si, target_is_not_directory
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_dir_exit

process_dir_create:
    call process_target_mkdir
    cmp ax, -1
    jz process_dir_exit

process_dir_copy:

    lea si, source 
    lea di, target
    call copydir

process_dir_exit:

    pop di
    pop si
    pop cx

    ret
process_dir endp

process_source proc

    push bx
    push cx
    push dx
    push si
    push di

    ; find first file
    mov cx, 111111b
    lea dx, source
    mov ah, 04eh
    int 21h
    jnc process_source_check_type

    lea si, source
    call puts
    lea si, open_error
    call puts
    lea si,lf
    call puts
    mov ax, -1
    jmp process_source_exit
   
process_source_next:
    ; find next file
    mov ah, 04fh
    int 21h
    jc process_source_exit_success

process_source_check_type:
    ; ignore '.' and '..'
    lea si, dta.dta_name
    lodsb
    cmp al, '.'
    jnz process_source_begin_copy
    lodsb
    or al, al
    jz process_source_next
    cmp al, '.'
    jnz process_source_begin_copy
    lodsb
    or al, al
    jz process_source_next

process_source_begin_copy:

    mov al, byte ptr [dta.dta_attr]
    test al, FILE_SUBDIRECTORY
    jz process_source_normal

    cmp [_opt_uR], 1
    jz process_source_dir

    lea si, error_recurse_omitted
    call puts
    lea si, omitting_directory
    call puts
    lea si, dta.dta_name
    call puts
    lea si, lf
    call puts
    jmp process_source_next

process_source_dir:

    ; convert to full path
    lea si, dta.dta_name
    lea di, source
    mov ah, 060h
    int 21h
    jnc process_source_dir_compare

    lea si, unable_to_convert_path 
    call puts
    lea si, dta.dta_name
    call puts
    lea si, lf
    call puts
    jmp process_source_next

process_source_dir_compare:

    ; compare file names
    lea di, source
    lea si, target
    mov dx, ds
    call sl_strcmp
    jne process_source_dir_clobber

    lea si, identical_files
    call puts
    lea si, dta.dta_name
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_source_next

process_source_dir_clobber:
    call copydir
    jmp process_source_next

process_source_normal:

    lea si, dta.dta_name
    lea di, target
    cmp byte ptr [target_type], FILE_SUBDIRECTORY
    jz process_source_switch_f2d

    call copyfile
    cmp ax, -1
    jz process_source_exit
    jmp process_source_next

process_source_switch_f2d:
    call copyf2d
    cmp ax, -1
    jz process_source_exit
    jmp process_source_next

process_source_exit_success:
    xor ax, ax

process_source_exit:

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret
process_source endp

; prep target
process_prep_target proc

    push si

    ; if target does not exist and source expands
    ; assume target is a directory and create it

    cmp byte ptr [target_type], 0
    jnz process_prep_target_exit_success

    lea si, source
    call process_does_file_expand
    or ax, ax
    jz process_prep_target_exit_success

    call process_target_mkdir
    mov byte ptr [target_type], FILE_SUBDIRECTORY

process_prep_target_exit_success:
    xor ax, ax

process_prep_target_exit:

    pop si

    ret
process_prep_target endp

public process
process proc

    cmp byte ptr [file_count], 1
    ja process_has_target

    lea si, missing_target_operand
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_exit

process_has_target:

    call process_target_setup
    cmp ax, -1
    je process_exit

    cmp byte ptr [file_count], 1
    je process_start

    ; target must be a subdirectory
    cmp [target_type], FILE_SUBDIRECTORY
    je process_start

    lea si, target_is_not_directory
    call puts
    lea si, lf
    call puts
    mov ax, -1
    jmp process_exit

process_start:
    lea si, [file_list]

process_next:
    mov bx, si ; save file list pointer
    call process_source_expand
    lea si, source
    call process_get_type
    cmp ax, FILE_SUBDIRECTORY
    jnz process_actual_source

    call process_dir
    cmp ax, -1
    je process_exit
    jmp process_list_next

process_actual_source:
    call process_prep_target
    call process_source
    cmp ax, -1
    je process_exit

process_list_next:
    mov si, bx ; restore file list pointer

process_list_next_find:
    lodsb
    or al, al
    jnz process_list_next_find
    cmp byte ptr [si], 0
    jnz process_next

process_exit:

    ret
process endp

end

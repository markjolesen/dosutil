; USAGE.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LS. This work is published 
; from: United States.

.186
.model small

.data

usage db "cp --- copy files",0dh,0ah
      db "-i   if file exists prompt to overwrite",0dh,0ah
      db "-p   preserve date and time",0dh,0ah
      db "-R   recursively copy directories",0dh,0ah
      db "$" 
      
.code

; usage_print
; outputs usage to stdout
; inputs: none
; outputs: none
; destroys: ax, dx
public usage_print
usage_print proc
    mov ah, 09h
    mov dx, offset usage
    int 21h
    ret
usage_print endp
      
end

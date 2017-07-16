; USAGE.ASM
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to WC. This work is published 
; from: United States.

.186
.model small

.data

usage db "wc --- count line and words",0dh,0ah
      db "-c   Write the number of bytes",0dh,0ah
      db "-h   Print help message and exit",0dh,0ah
      db "-l   Write the number of lines",0dh,0ah
      db "-w   Write the number of words",0dh,0ah
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

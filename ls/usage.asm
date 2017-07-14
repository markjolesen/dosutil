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

usage db "ls --- list directory contents",0dh,0ah
      db "-C   Write multi-column output with entries sorted down the columns",0dh,0ah
      db "-F   Write a slash ('/') after each entry that is a directory",0dh,0ah
      db "     Write an asterisk ('*') after each entry that is an executable",0dh,0ah
      db "-R   Recursively list subdirectories",0dh,0ah
      db "-S   Sort on file size in decreasing order",0dh,0ah
      db "-a   Write out hidden files",0dh,0ah
      db "-f   List entries in the order they appear",0dh,0ah
      db "-h   Print help message and exit.",0dh,0ah
      db "-l   Write out entries in long format",0dh,0ah
      db "-m   Write output in comma separated format",0dh,0ah
      db "-p   Write a slash ('/') after each directory",0dh,0ah
      db "-r   Reverse sort order",0dh,0ah
      db "-t   Sort on time modified",0dh,0ah
      db "-x   Write multi-column output with entries sorted accross the columns",0dh,0ah
      db "-1   Write entries one per line",0dh,0ah
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

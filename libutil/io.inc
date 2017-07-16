; IO.INC
;
; License CC0 PUBLIC DOMAIN
;
; To the extent possible under law, Mark J. Olesen has waived all copyright 
; and related or neighboring rights to LIBUTIL. This work is published 
; from: United States.


FILE_READ_ONLY    EQU 0x01
FILE_HIDDEN       EQU 0x02
FILE_SYSTEM       EQU 0x04
FILE_VOLUME_LABEL EQU 0x08
FILE_SUBDIRECTORY EQU 0x10
FILE_ARCHIVE      EQU 0x20

; freedos kernel dmatch data structure (dirmatch.h)
disk_transfer_area struc
  dta_drive         db ?
  dta_name_pat      db 11 dup(?)
  dta_attr_srch     db ?
  dta_entry         dw ?
  dta_dircluster    dd ?
  dta_resv1         dw ?
  dta_attr          db ?
  dta_time          dw ?
  dta_date          dw ?
  dta_size          dd ?
  dta_name          db 13 dup(?)
disk_transfer_area ends

file_info struc
  fi_attr          db ?
  fi_time          dw ?
  fi_date          dw ?
  fi_size          dd ?
  fi_name          db 13 dup(?)
file_info ends

filename struc
  fn_name          db 13 dup(?)
filename ends

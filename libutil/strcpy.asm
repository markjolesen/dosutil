; UCR Standard Library for 80x86 Assembly Language Programmers (v34) 
; Written by Randall Hyde and others.  Submissions cheerfully accepted
; This software is public domain and may be freely used for any purpose

.186
.model small

.code

;
;
; strcpy- Copies string pointed at by es:di to string pointed at by dx:si.
;	  (Sorry for the ackward use of registers, this matches the rest
;	   of the standard library though).
;
; inputs:
;		es:di-	Zero-terminated source string.
;		dx:si-  Buffer for destination string.
;
; outputs:	es:di-	Points at destination string.
;
; Note: The destination buffer must be large enough to hold the string and
;	zero terminating byte.
;
		public	sl_strcpy
;
sl_strcpy	proc
		push	ds
		push	cx
		push	ax
		pushf
		push	si
;
		cld
		mov	al, 0
		mov	cx, 0ffffh
		push	di
	repne	scasb
		pop	di
		neg	cx
		mov	ax, es
		mov	ds, ax
		mov	es, dx
		xchg	si, di
		dec	cx
		shr	cx, 1
		jnc	CpyWrd
		lodsb
		stosb
CpyWrd:	rep	movsw
;
DidByte:	pop	si
		popf
		pop	ax
		pop	cx
		pop	ds
		mov	es, dx
		mov	di, si
		ret
sl_strcpy		endp
;
;
		end

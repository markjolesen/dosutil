
AS=wasm
AFLAGS=-bt=DOS -d1

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3

OBJS=&
	itoa.obj &
	ltoa.obj &
	puts.obj &
	qsort.obj &
	strcmp.obj

libutil.lib : $(OBJS)
	wlib $@ @libutil.lbc

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<

clean: .SYMBOLIC
	@rm -f *.obj  *.lib

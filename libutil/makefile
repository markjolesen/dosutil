
AS=wasm
AFLAGS=-bt=DOS -d1

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3

OBJS=&
	norm.obj &
	itoa.obj &
	ltoa.obj &
	path.obj &
	puts.obj &
	qsort.obj &
	strcmp.obj &
	strcpy.obj

libutil.lib : $(OBJS)
	wlib $@ @libutil.lbc

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<

clean: .SYMBOLIC
	@rm -f *.obj  *.lib


AS=wasm
AFLAGS=-bt=DOS -d1

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3

OBJS=&
	cmp.obj &
	dirbuf.obj &
	fetch.obj &
	filebuf.obj &
	itoa.obj &
	ltoa.obj &
	main.obj &
	option.obj &
	path.obj &
	print.obj &
	process.obj &
	puts.obj &
	usage.obj &
	qsort.obj &
	strcmp.obj
    
ls.exe : $(OBJS) 
	*wlink name ls.exe format dos debug all op map file $(OBJS: =,)

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<

clean: .SYMBOLIC
	@rm -f *obj ls.exe *.map

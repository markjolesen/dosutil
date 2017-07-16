
AS=wasm
AFLAGS=-bt=DOS -d1

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3

OBJS=&
	cmp.obj &
	dirbuf.obj &
	fetch.obj &
	filebuf.obj &
	main.obj &
	option.obj &
	path.obj &
	print.obj &
	process.obj &
	usage.obj
    
ls.exe : $(OBJS)  ..\libutil\libutil.lib
	*wlink name ls.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<
	
..\libutil\libutil.lib :
	@cd ..\libutil
	@wmake 
	@cd ..\ls

clean: .SYMBOLIC
	@rm -f *.obj ls.exe *.map

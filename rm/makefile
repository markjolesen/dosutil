
AS=wasm
AFLAGS=-bt=DOS -d1 -i=..\libutil

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3 -i=..\libutil

OBJS=&
	main.obj &
	option.obj &
	path.obj &
	process.obj &
	rmfile.obj &
	usage.obj

rm.exe : $(OBJS)  ..\libutil\libutil.lib
	*wlink name rm.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<
	
..\libutil\libutil.lib :
	@cd ..\libutil
	@wmake 
	@cd ..\rm

clean: .SYMBOLIC
	@rm -f *.obj rm.exe *.map

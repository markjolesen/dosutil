
AS=wasm
AFLAGS=-bt=DOS -d1 -i=..\libutil

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3 -i=..\libutil

OBJS=&
	copydir.obj &
	copyfile.obj &
	copyf2d.obj &
	main.obj &
	option.obj &
	path.obj &
	process.obj &
	usage.obj

cp.exe : $(OBJS)  ..\libutil\libutil.lib
	*wlink name cp.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<
	
..\libutil\libutil.lib :
	@cd ..\libutil
	@wmake 
	@cd ..\cp

clean: .SYMBOLIC
	@rm -f *.obj cp.exe *.map

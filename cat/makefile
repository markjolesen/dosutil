
AS=wasm
AFLAGS=-bt=DOS -d1 -i=..\libutil

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3 -i=..\libutil

OBJS=&
	main.obj &
	option.obj &
	process.obj &
	usage.obj
    
cat.exe : $(OBJS)  ..\libutil\libutil.lib
	*wlink name cat.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<
	
..\libutil\libutil.lib :
	@cd ..\libutil
	@wmake 
	@cd ..\cat

clean: .SYMBOLIC
	@rm -f *.obj cat.exe *.map

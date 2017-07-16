
AS=wasm
AFLAGS=-bt=DOS -d1 -i=..\libutil

CC=wcc
CFLAGS=-1 -ms -s -zls -bt=DOS -d3 -i=..\libutil

OBJS=&
	main.obj &
	option.obj &
	print.obj &
	process.obj &
	usage.obj
    
wc.exe : $(OBJS)  ..\libutil\libutil.lib
	*wlink name wc.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj :
        $(CC) $(CFLAGS) $<
	
..\libutil\libutil.lib :
	@cd ..\libutil
	@wmake 
	@cd ..\wc

clean: .SYMBOLIC
	@rm -f *.obj wc.exe *.map

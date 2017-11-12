
AS=wasm
AFLAGS=-bt=DOS -d1 -i=..\libutil

CC=wcc

OBJS=&
        main.obj &
        mkdir.obj &
        option.obj &
        path.obj &
        process.obj &
        usage.obj

mkdir.exe : $(OBJS)  ..\libutil\libutil.lib
        *wlink name mkdir.exe format dos debug all op map file $(OBJS: =,) library ..\libutil\libutil.lib

.asm.obj :
        $(AS) $(AFLAGS) $<
        
        
..\libutil\libutil.lib :
        @cd ..\libutil
        @wmake 
        @cd ..\mkdir

clean: .SYMBOLIC
        @rm -f *.obj mkdir.exe *.map


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
        wlink @ls.lnk

.asm.obj :
        $(AS) $(AFLAGS) $<
        
.c.obj:
        $(CC) $(CFLAGS) $<

clean: .SYMBOLIC
        @if exist *.obj del *.obj
        @if exist ls.exe del ls.exe    
        @if exist *.map del *.map
    


# rm

remove files

# SYNOPSIS

cp [OPTION]... source target

# DESCRIPTION

-h   Print help message and exit

-i   If file exists prompt to overwrite

-R   Recursively remove subdirectories

# Compiling

Code is in assembly language. Requires OpenWatcom C/C++ compiler.

```
wmake /a 
```

This will compile with debugger information. To strip, use the following
command.

```
wstrip rm.exe
```
 

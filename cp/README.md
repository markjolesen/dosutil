
# cp

copy files

# SYNOPSIS

cp [OPTION]... source target

# DESCRIPTION

-i   If file exists prompt to overwrite

-p   Preserve date and time

-R   Recursively copy subdirectories

# Compiling

Code is in assembly language. Requires OpenWatcom C/C++ compiler.

```
wmake /a 
```

This will compile with debugger information. To strip, use the following
command.

```
wstrip cp.exe
```
 

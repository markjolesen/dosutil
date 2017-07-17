
# cat

concatenate and print files

# SYNOPSIS

cat [OPTION]... [FILE]...

# DESCRIPTION

-u   Write the number of bytes

-h   Print help message and exit

FILE can be '-' for stdin.

# Compiling

Code is written in assembly language. Requires OpenWatcom C/C++ compiler.

```
wmake /a 
```

This will compile with debugger information. To strip, use the following
command.

```
wstrip cat.exe
```
 


# wc

count lines and words

# SYNOPSIS

wc [OPTION]... [FILE]...

# DESCRIPTION

-c   Write the number of bytes

-h   Print help message and exit

-l   Write the number of lines

-w   Write the number of words


# Compiling

Code is written in assembly language. Requires OpenWatcom C/C++ compiler.

```
wmake /a 
```

This will compile with debugger information. To strip, use the following
command.

```
wstrip ls.exe
```
 

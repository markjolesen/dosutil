
# ls

list directory contents

# SYNOPSIS

ls [OPTION]... [FILE]...

# DESCRIPTION

-C   Write multi-column output with entries sorted down the columns

-F   Write a slash ('/') after each entry that is a directory
     Write an asterisk ('*') after each entry that is an executable

-R   Recursively list subdirectories

-S   Sort on file size in decreasing order

-a   Write out hidden files

-f   List entries in the order they appear

-h   Print help message and exit

-l   Write out entries in long format

-m   Write output in comma separated format

-p   Write a slash ('/') after each directory

-r   Reverse sort order

-t   Sort on time modified

-x   Write multi-column output with entries sorted across the columns

-1   Write entries one per line

# Compiling

Code is a hybrid of assembly and C language. Requires OpenWatcom C/C++
compiler.

```
wmake /a 
```

This will compile with debugger information. To strip, use the following
command.

```
wstrip ls.exe
```
 

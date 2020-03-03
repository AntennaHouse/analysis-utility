# analysis-utility
Stylesheets and scripts for working with the results from AH Formatter automated analysis.

## Windows

````
usage: analyzer [-lang lang] [-ahfcmd AHFCmd] -d file [-opt "options"]
       lang    : Language for error messages -- en or ja
       AHFCmd  : Path to AHFCmd.exe
       file    : File to format and analyze
       options : Additional AHFCmd command-line parameters
````

Requires `msxsl.exe` to be in the current directory or on the PATH. `msxsl.exe` can be downloaded from https://www.microsoft.com/en-us/download/details.aspx?id=21714

## Linux

````
usage: analyzer.sh file
       file    : File to format and analyze
````

Requires `xsltproc` to be on the path.

Expects AH Formatter to be installed at `/usr/AHFormatterV7_64/`.

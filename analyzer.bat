@echo off
rem $Id$

rem    Copyright 2020 Antenna House, Inc.
rem 
rem    Licensed under the Apache License, Version 2.0 (the "License");
rem    you may not use this file except in compliance with the License.
rem    You may obtain a copy of the License at
rem 
rem        http://www.apache.org/licenses/LICENSE-2.0
rem 
rem    Unless required by applicable law or agreed to in writing, software
rem    distributed under the License is distributed on an "AS IS" BASIS,
rem    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
rem    implied.
rem
rem    See the License for the specific language governing permissions and
rem    limitations under the License.


rem Download msxsl.exe from:
rem    https://www.microsoft.com/en-us/download/details.aspx?id=21714

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set REPORTER_XSLT=ahfcmd-reporter.xsl

if "%1"=="" goto usage

goto start

:usage
echo.
echo Analyze a formatted file and generate annotated PDF
echo.
echo usage: analyzer [-lang lang] [-ahfcmd AHFCmd] -d file [-opt "options"]
echo        lang    : Language for error messages -- en or ja
echo        AHFCmd  : Path to AHFCmd.exe
echo        file    : File to format and analyze
echo        options : Additional AHFCmd command-line parameters
echo.
goto done

rem ----------------------------------------------------------------------
:start

rem Command-line argument handling based on:
rem    https://stackoverflow.com/a/32078177
rem    https://stackoverflow.com/a/54234876

rem Command-line parameter defaults
set lang=en
set ahfcmd=
set d=
set opt=

rem List of all recognized parameter names.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __all_param= ahfcmd lang d opt 

set __expect_param_name=yes

:initial
if "%~1"=="" goto parameters_done
if "%~1"=="--" (
   shift
   goto parameters_done
)

rem echo              %1
set aux=%~1
if "%__expect_param_name%"=="yes" (
if "%aux:~0,1%"=="-" (
   rem Parameter name.
   set __param=%aux:~1,250%
   rem Parameter name with a space charater before and after the name.
   rem You can't see the final ' ', but it has to be there.
   set __param_tmp= %aux:~1,250% 
   rem echo __param: "!__param!"
   rem echo __param: "%__param%"
   rem echo __param_tmp: "!__param_tmp!"
   rem echo __param_tmp: "%__param_tmp%"
   rem The two strings match only if __param is not in the list.
   call set __param_removed=%%__all_param:!__param_tmp!=%%
   rem Remove transient variables
   set __param_tmp=
   rem echo __param_removed: "!__param_removed!"
   rem echo __param_removed: "%__param_removed%"
   rem set __param_removed=
   set __expect_param_name=
) else (
  echo.
  echo Expected a parameter starting with "-": %aux%
  )
) else (
   rem echo __param_removed: "!__param_removed!"
   rem echo __param_removed: "%__param_removed%"
   rem List of all parameter names, possibly with __param removed.
   if "x%__param_removed%"=="x%__all_param%" (
      echo Unrecognized parameter: -!__param!
      goto error
   )
   set "%__param%=%~1"
   set __param=
   set __expect_param_name=yes
)
shift
goto initial
:parameters_done

set FILE=%d%

if not exist %d% (
   echo.
   echo Source file does not exist: %d%
   goto error
)
set BASENAME=
for /F  %%I in ("%FILE%") do set BASENAME=%%~nI

rem echo %FILE%%BASENAME%

if not "%BASENAME%"=="" goto have_basename
echo Could not determine basename for %FILE%
goto error

:have_basename

rem echo opt: %opt%

if not "%ahfcmd%"=="" (
   if EXIST "%ahfcmd%" (
      set AHFCMD=%ahfcmd%
   ) else (
      echo AHFCmd file does not exist: %ahfcmd%
      goto error
   )
) else if not "%AHF70_64_HOME%"=="" (
   if EXIST "%AHF70_64_HOME%\AHFCmd.exe" (
      set AHFCMD=%AHF70_64_HOME%\AHFCmd.exe
   ) else (
      echo AHFCmd file does not exist in '%AHF70_64_HOME%'
      goto error
   )
) else if not "%AHF70_HOME%"=="" (
   if EXIST "%AHF70_HOME%\AHFCmd.exe" (
      set AHFCMD=%AHF70_HOME%\AHFCmd.exe
   ) else (
      echo AHFCmd file does not exist in '%AHF70_HOME%'
      goto error
   )
) else (
  echo No AHFCmd.exe
  goto error
)

if exist %BASENAME%.AT.XML del %BASENAME%.AT.XML

"%AHFCMD%" -analyze -p @AreaTree -xmlerr -d %FILE% %opt% -o %BASENAME%.AT.XML 2> %BASENAME%.log.xml

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when analyzing '%FILE%'. Check log file '%BASENAME%.log.xml'.
   goto error
)

if not exist %BASENAME%.AT.XML (
   echo Area Tree XML file for '%FILE%' was not created. Check log file '%BASENAME%.log.xml'.
   goto error
)

msxsl %BASENAME%.AT.xml %REPORTER_XSLT% -o annotated-%BASENAME%.AT.xml logfile=%BASENAME%.log.xml lang=%lang%
rem xsltproc --stringparam logfile %BASENAME%.log.xml --stringparam lang %lang% -o annotated-%BASENAME%.AT.xml %REPORTER_XSLT% %BASENAME%.AT.xml

if %ERRORLEVEL% NEQ 0 (
   echo.
   echo An error occurred when creating the annotated Area Tree XML file.
   goto error
)

rem If the PDF is open in Acrobat, it can't be either deleted or replaced.
if exist annotated-%BASENAME%.pdf del annotated-%BASENAME%.pdf
if exist annotated-%BASENAME%.pdf (
   echo Unable to replace 'annotated-%BASENAME%.pdf'.
   goto error
)

"%AHFCMD%" -x 4 -d annotated-%BASENAME%.AT.xml -o annotated-%BASENAME%.pdf 2> annotated-%BASENAME%.log.txt

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when generating 'annotated-%BASENAME%.pdf'. Check log file 'annotated-%BASENAME%.log.txt'.
   goto error
)

rem View the PDF
if exist annotated-%BASENAME%.pdf (
   annotated-%BASENAME%.pdf 
) else (
   echo An error occurred when generating 'annotated-%BASENAME%.pdf'. Check log file 'annotated-%BASENAME%.log.txt'.
   goto error
)

rem ----------------------------------------------------------------------
:done

exit /B 0

rem ----------------------------------------------------------------------
:error
exit /B 1

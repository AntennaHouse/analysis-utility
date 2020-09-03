@echo off

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

rem Directory locations
set PWD=%cd%
rem Value of '%~dp0' includes trailing '\'.
set ANALYZER_DIR=%~dp0
set LIB_DIR=%ANALYZER_DIR%lib
set XSL_DIR=%ANALYZER_DIR%xsl

rem Command-line parameter defaults (possibly used in 'usage' message)
set ahfcmd=
set d=
set force=
set format=annotate
set lang=en
set opt=
set pdfver=PDF1.7
set transformer=
set xslt=
set xsltparam=

if "%1"=="" goto usage

goto start

:usage
echo.
echo Analyze a formatted file and generate annotated PDF

:usage_command_line
echo.
echo usage: analyzer -d file [-format format] [-lang lang]
echo                 [-ahfcmd AHFCmd] [-opt "options"]
echo                 [-xslt xslt] [-xsltparam "xslt-params" ]
echo                 [-transformer transformer ]
echo                 [-pdfver pdfver] [-force yes]
echo.
echo        file    : File to format and analyze
echo        format  : Analysis result format -- annotate or report
echo                  Default is '%format%'
echo        lang    : Language for error messages -- en or ja
echo                  Default is '%lang%'
echo        AHFCmd  : Path to AHFCmd.exe
echo        options : Additional AHFCmd command-line parameters
echo        xslt    : XSLT stylesheet to use
echo        xslt-params : XSLT processor parameters
echo        transformer : XSLT 1.0 processor -- msxsl, xsltproc, or saxon6
echo                      Used with 'annotate' result format only
echo        pdfver  : PDF version of reports. Default is '%pdfver%'
echo        -force yes  : Force all stages to run
echo.
goto done

rem ----------------------------------------------------------------------
:start

rem Command-line argument handling based on:
rem    https://stackoverflow.com/a/32078177
rem    https://stackoverflow.com/a/54234876

rem List of names of recognized parameters that do not require a value.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __short_param= f

rem List of names of recognized parameters that require a value.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __long_param= ahfcmd d force format lang opt pdfver transformer xslt xsltparam 

rem List of all recognized parameter names.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __all_param= %__short_param% %__long_param%  

set __expect_param_name=yes

:initial
if "%~1"=="" goto parameters_done
if "%~1"=="--" (
   shift
   goto parameters_done
)

rem echo              %1
set aux=%~1
rem if "%__expect_param_name%"=="yes" (
if not "%__expect_param_name%"=="yes" goto parameters_value
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
   shift
   goto initial
) else (
  echo.
  echo Expected a parameter starting with "-": %aux%
  goto usage_command_line
  )
:parameters_value
rem ) else (
   rem echo __param_removed: "!__param_removed!"
   rem echo __param_removed: "%__param_removed%"
   rem List of all parameter names, possibly with __param removed.
   if "x%__param_removed%"=="x%__all_param%" (
      echo.
      echo Unrecognized parameter: -!__param!
      goto usage_command_line
   )
   set "%__param%=%~1"
   set __param=
   set __expect_param_name=yes
rem )
shift
goto initial
:parameters_done

set FILE=%d%

if not exist "%d%" (
   echo.
   echo Source file does not exist: '%d%'
   goto error
)
set BASENAME=
call :sub_basename BASENAME "%FILE%"
set EXT=
call :sub_ext EXT "%FILE%"

rem echo '%FILE%' '%BASENAME%'

if not "%BASENAME%"=="" goto have_basename
echo Could not determine basename for %FILE%
goto error

:have_basename

rem echo opt: %opt%


set REPORTER_XSLT=%XSL_DIR%\annotate.xsl
if "%format%"=="report" (
rem Default 'report' format is 'compact' format.
   set REPORTER_XSLT=%XSL_DIR%\compact-report.xsl
) else if "%format%"=="compact" (
rem 'compact' was used internally but never in a public release.
   set REPORTER_XSLT=%XSL_DIR%\compact-report.xsl
)

if not "%xslt%"=="" (
   if EXIST "%xslt%" (
      set REPORTER_XSLT=%xslt%
   ) else (
      echo XSLT file does not exist: %xslt%
      goto error
   )
)

if not "%ahfcmd%"=="" (
   if EXIST "%ahfcmd%" (
      set AHFCMD="%ahfcmd%"
      goto ahfcmd_done
   ) else (
      echo AHFCmd file does not exist: %ahfcmd%
      goto error
   )
) else if not "%AHF70_64_HOME%"=="" (
   if EXIST "%AHF70_64_HOME%\AHFCmd.exe" (
      set AHFCMD="%AHF70_64_HOME%\AHFCmd.exe"
      goto ahfcmd_done
   ) else (
      echo AHFCmd file does not exist in '%AHF70_64_HOME%'
      goto error
   )
)

rem The '(86)' in %AHFXX_HOME% value causes problem when %AHFXX_HOME%
rem is used in an 'if' statement that includes '(' and ')'.  It is
rem necessary to do the check a different way.
if "%AHF70_HOME%"=="" (
  echo No AHFCmd.exe
  goto error
)

if EXIST "%AHF70_HOME%\AHFCmd.exe" goto ahfcmd_ahfxx_home

echo AHFCmd file does not exist in '%AHF70_HOME%'
goto error

:ahfcmd_ahfxx_home

set AHFCMD="%AHF70_HOME%\AHFCmd.exe"

:ahfcmd_done

rem echo %AHFCMD%

rem Check format value before taking time to generate Area Tree XML.
if not "%format%"=="annotate" (
   if not "%format%"=="compact" (
      if not "%format%"=="report" (
      	 echo Unrecognized result format: %format%
   	 goto error
      )
   )
)

rem All of the reasons to generate "%BASENAME%.AT.XML" ...

if "%force%"=="yes" goto at_do

if not exist "%BASENAME%.AT.XML" goto at_do

rem Sort files by date. Newer file is last to set NEWER.
for /F "usebackq delims=" %%q in (`dir /B /OD "%FILE%" "%BASENAME%.AT.XML"`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.AT.XML" goto at_do

rem 'dir /B /OD' does not work across directories.
rem Use a function that returns timestamp in seconds since 1970.
if exist "%BASENAME%.AT.XML" call :sub_file_mod_time "%BASENAME%.AT.XML" AT_XML_DATE
call :sub_file_mod_time %AHFCMD% AHFCMD_DATE

if "%AHFCMD_DATE%" GTR "%AT_XML_DATE%" goto at_do

rem No need to regenerate %BASENAME%.AT.XML
echo '%BASENAME%.AT.XML' is up to date

goto at_done

:at_do

echo Analyzing '%FILE%' and generating '%BASENAME%.AT.XML'

if exist "%BASENAME%.AT.XML" del "%BASENAME%.AT.XML"
if exist "%BASENAME%.AT.XML" (
   echo Unable to replace '%BASENAME%.AT.XML'.
   goto error
)

%AHFCMD% -analyze -p @AreaTree -xmlerr -d "%FILE%" %opt% -o "%BASENAME%.AT.XML" 2> "%BASENAME%.log.xml"

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when analyzing '%FILE%'. Check log file '%BASENAME%.log.xml'.
   goto error
)

if not exist "%BASENAME%.AT.XML" (
   echo Area Tree XML file for '%FILE%' was not created. Check log file '%BASENAME%.log.xml'.
   goto error
)

:at_done

if "%format%"=="annotate" (
   goto annotate
) else if "%format%"=="compact" (
   goto report
) else if "%format%"=="report" (
   goto report
) else (
   echo Unrecognized result format: %format%
   goto error
)

rem ----------------------------------------------------------------------
:annotate

if not "%transformer%"=="" (
   rem This sccipt does NOT check that specified transformer is available.

   if "%transformer%"=="msxsl" (
      call :sub_msxsl
      goto annotate_done_xslt
   )

   if "%transformer%"=="xsltproc" (
      call :sub_xsltproc
      goto annotate_done_xslt
   )

   if "%transformer%"=="saxon6" (
      call :sub_saxon6
      goto annotate_done_xslt
   )

   echo Unrecognized XSLT transformer: %transformer%
   goto error
)

call :sub_on_path msxsl.exe
if not "%__SUB_ON_PATH_MATCH%"=="" (
   call :sub_msxsl
   goto annotate_done_xslt
)

call :sub_on_path xsltproc.exe
if not "%__SUB_ON_PATH_MATCH%"=="" (
   call :sub_xsltproc
   goto annotate_done_xslt
)

call :sub_on_path java.exe
if not "%__SUB_ON_PATH_MATCH%"=="" (
   call :sub_saxon6
   goto annotate_done_xslt
)

rem No XSLT processor is available.
echo Either msxsl.exe, xsltproc.exe, or java.exe must be in a directory on the PATH.
goto error

:annotate_done_xslt

if %ERRORLEVEL% NEQ 0 (
   echo.
   echo An error occurred when creating the annotated Area Tree XML file.
   goto error
)

call :sub_2pdf "%PWD%\%BASENAME%.annotated.AT.xml" "%PWD%\%BASENAME%.annotated.pdf" "%PWD%\%BASENAME%.annotated.pdf.log"

if %ERRORLEVEL% NEQ 0 goto error

rem View the PDF
if exist "%BASENAME%.annotated.pdf" (
   echo Analysis completed.
   echo Annotated PDF: '%BASENAME%.annotated.pdf'
   "%BASENAME%.annotated.pdf"
) else (
   echo An error occurred when generating '%BASENAME%.annotated.pdf'. Check log file '%BASENAME%.annotated.pdf.log'.
   goto error
)

rem ----------------------------------------------------------------------
:done

exit /B 0

rem ----------------------------------------------------------------------
:error
exit /B 1

rem ----------------------------------------------------------------------
:report

if not "%transformer%"=="" (
   echo '-transformer' is ignored unless '-format annotate'
)

rem Whether or not to regenerate %BASENAME%.pdf...

if "%force%"=="yes" goto report_pdf_do

for /F "usebackq delims=" %%q in (`dir /B /OD "%BASENAME%%EXT%" "%BASENAME%.pdf"`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.pdf" goto report_pdf_do

rem 'dir /B /OD' does not work across directories.
rem Use a function that returns timestamp in seconds since 1970.
if exist "%BASENAME%.pdf" call :sub_file_mod_time "%BASENAME%.pdf" PDF_DATE
call :sub_file_mod_time %AHFCMD% AHFCMD_DATE

if "%AHFCMD_DATE%" GTR "%PDF_DATE%" goto report_pdf_do

echo '%BASENAME%.pdf' is up to date
goto report_pdf_done

:report_pdf_do

call :sub_2pdf "%PWD%\%BASENAME%%EXT%" "%PWD%\%BASENAME%.pdf" "%PWD%\%BASENAME%.pdf.log" "%opt%"

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when generating '%BASENAME%.pdf'. Check log file '%BASENAME%.pdf.log'.
   goto error
)

:report_pdf_done

rem Whether or not to regenerate %BASENAME%.report.fo...

for /F "delims=" %%q in ('dir /B /OD "%BASENAME%%EXT%" "%BASENAME%.log.xml" "%BASENAME%.report.fo"') do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.report.fo" goto report_fo_do

echo '%BASENAME%.report.fo' is up to date
goto report_fo_done

:report_fo_do

call :sub_on_path java.exe
if "%__SUB_ON_PATH_MATCH%"=="" (
   rem Java is not available.
   echo java.exe must be in a directory on the PATH.
   goto error
)

call :sub_mod_date FO_DATE "%BASENAME%.fo"

echo Generating '%BASENAME%.report.fo' from '%BASENAME%.AT.xml'
java -jar "%LIB_DIR%\saxon9he.jar" "-s:%PWD:\=/%/%BASENAME%.AT.xml" "-xsl:%REPORTER_XSLT:\=/%" "-o:%BASENAME%.report.fo" "logfile=file:///%PWD%/%BASENAME%.log.xml" lang=%lang% "file=%PWD:\=/%/%BASENAME%.fo" file-date="%FO_DATE%" "pdf-file=%PWD:\=/%/%BASENAME%.pdf" %xsltparam%

if %ERRORLEVEL% NEQ 0 (
   echo.
   echo An error occurred when creating the report XSL-FO file.
   goto error
)

:report_fo_done


rem Whether or not to regenerate %BASENAME%.report.pdf...

for /F "usebackq delims=" %%q in (`dir /B /OD "%BASENAME%.report.fo" "%BASENAME%.report.pdf"`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.report.pdf" goto report_pdf_do

echo '%BASENAME%.report.pdf' is up to date
goto report_pdf_done

:report_pdf_do

call :sub_2pdf "%PWD%\%BASENAME%.report.fo" "%PWD%\%BASENAME%.report.pdf" "%PWD%\%BASENAME%.report.pdf.log" "-pdfver %pdfver%"

if %ERRORLEVEL% NEQ 0 goto error

:report_pdf_done

rem View the PDF
if exist "%BASENAME%.report.pdf" (
   echo Analysis completed.
   echo Report PDF: '%BASENAME%.report.pdf'
   "%BASENAME%.report.pdf"
) else (
   echo An error occurred when generating '%BASENAME%.report.pdf'. Check log file '%BASENAME%.report.pdf.log'.
   goto error
)

goto done

rem ----------------------------------------------------------------------
rem Subroutines

:sub_on_path
rem echo %1
set __SUB_ON_PATH_MATCH=%~$PATH:1
exit /B 1

:sub_basename
rem echo %1 %2
set "%~1=%~n2"
exit /B 1

:sub_basename_ext
rem echo %1 %2
set "%~1=%~nx2"
exit /B 1

:sub_ext
rem echo %1 %2
set "%~1=%~x2"
exit /B 1

:sub_mod_date
rem echo %1 %2
set "%~1=%~t2"
exit /B 1

:sub_msxsl
msxsl "%BASENAME%.AT.xml" "%REPORTER_XSLT%" -o "%BASENAME%.annotated.AT.xml" logfile="%PWD%/%BASENAME%.log.xml" lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_xsltproc
xsltproc --stringparam logfile "%PWD%/%BASENAME%.log.xml" --stringparam lang %lang% %xsltparam% -o "%BASENAME%.annotated.AT.xml" "%REPORTER_XSLT%" "%PWD%/%BASENAME%.AT.xml"
exit /B %ERRORLEVEL%

:sub_saxon6
java -jar "%LIB_DIR%\saxon.jar" -o "%BASENAME%.annotated.AT.xml" "%PWD:\=/%/%BASENAME%.AT.xml" "%REPORTER_XSLT:\=/%" "logfile=file:///%PWD%/%BASENAME%.log.xml" lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_saxon9
java -jar "%LIB_DIR%\saxon9he.jar" "-s:%PWD:\=/%/%BASENAME%.AT.xml" "-xsl:%REPORTER_XSLT:\=/%" "-o:%BASENAME%.report.fo" "logfile=file:///%PWD%/%BASENAME%.log.xml" lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_2pdf

set SOURCE=%~1
set TARGET=%~2
set LOG=%~3
set PDF_OPT=%~4

rem If the PDF is open in Acrobat, it can't be either deleted or replaced.
if exist "%TARGET%" del "%TARGET%"
if exist "%TARGET%" (
   echo Unable to replace '%TARGET%'.
   exit /B 1
)

set SOURCE_BASENAME=
call :sub_basename_ext SOURCE_BASENAME "%SOURCE%"

set TARGET_BASENAME=
call :sub_basename_ext TARGET_BASENAME "%TARGET%"

echo Formatting '%SOURCE_BASENAME%' as '%TARGET_BASENAME%'
rem Use highest-possible PDF version in case embedding high-version PDF
%AHFCMD% -x 4 %PDF_OPT% -d "%SOURCE%" -o "%TARGET%" 2> "%LOG%"

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when generating '%TARGET%'. Check log file '%LOG%'.
   exit /B 1
)
exit /B 0

rem From https://www.dostips.com/forum/viewtopic.php?p=38229#p38229
:sub_file_mod_time  File  [TimeVar]
::
::  Computes the Unix time (epoch time) for the last modified timestamp for File.
::  The result is an empty string if the file does not exist. Stores the result
::  in TimeVar, or prints the result if TimeVar is not specified.
::
::  Unix time = number of seconds since midnight, January 1, 1970 GMT
::
setlocal disableDelayedExpansion
:: Get full path of file (short form if possible)
for %%F in ("%~1") do set "file=%%~sF"
:: Get last modified time in YYYYMMDDHHMMSS format
set "time="
for /f "skip=1 delims=,. tokens=2" %%A in (
  'wmic datafile where name^="%file:\=\\%" get lastModified /format:csv 2^>nul'
) do set "ts=%%A"
set "ts=%ts%"
:: Convert time to Unix time (aka epoch time)
if defined ts (
  set /a "yy=10000%ts:~0,4% %% 10000, mm=100%ts:~4,2% %% 100, dd=100%ts:~6,2% %% 100"
  set /a "dd=dd-2472663+1461*(yy+4800+(mm-14)/12)/4+367*(mm-2-(mm-14)/12*12)/12-3*((yy+4900+(mm-14)/12)/100)/4"
  set /a "ss=(((1%ts:~8,2%*60)+1%ts:~10,2%)*60)+1%ts:~12,2%-366100-%ts:~21,1%((1%ts:~22,3%*60)-60000)"
  set /a "ts=ss+dd*86400"
)
:: Return the result
endlocal & if "%~2" neq "" (set "%~2=%ts%") else echo(%ts%

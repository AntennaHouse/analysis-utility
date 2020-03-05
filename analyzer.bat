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

set PWD=%cd%
rem Value of '%~dp0' includes trailing '\'.
set ANALYZER_DIR=%~dp0
set LIB_DIR=%ANALYZER_DIR%lib
set XSL_DIR=%ANALYZER_DIR%xsl

if "%1"=="" goto usage

goto start

:usage
echo.
echo Analyze a formatted file and generate annotated PDF
echo.
echo usage: analyzer -d file [-format format] [-lang lang]
echo                 [-ahfcmd AHFCmd] [-opt "options"]
echo                 [-xslt xslt] [-xsltparam "xslt-params" ]
echo                 [-transformer transformer ]
echo                 [-force yes]
echo        file    : File to format and analyze
echo        format  : Analysis result format -- annotate or report
echo                  Default is annotate
echo        lang    : Language for error messages -- en or ja
echo        AHFCmd  : Path to AHFCmd.exe
echo        options : Additional AHFCmd command-line parameters
echo        xslt    : XSLT stylesheet to use
echo        xslt-params : XSLT processor parameters
echo        transformer : XSLT 1.0 processor -- msxsl, xsltproc, or saxon6
echo        -force yes  : Force all stages to run
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
set xslt=
set xsltparam=
set transformer=
set format=annotate
set force=

rem List of names of recognized parameters that do not require a value.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __short_param= f

rem List of names of recognized parameters that require a value.
rem There must be at least one space (' ') at the beginning and end of
rem the list and between parameter names.
set __long_param= ahfcmd lang d opt xslt xsltparam transformer format force

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


set REPORTER_XSLT=%XSL_DIR%\ahfcmd-reporter.xsl
if "%format%"=="report" (
   set REPORTER_XSLT=%XSL_DIR%\ahfcmd-reporter-xslt3.xsl
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


rem All of the reasons to generate %BASENAME%.AT.XML...

if "%force%"=="yes" goto at

if not exist %BASENAME%.AT.XML goto at

for /F "usebackq" %%q in (`dir /B /OD %FILE% %BASENAME%.AT.XML`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.AT.XML" goto at

FOR %%? IN ("%AHFCMD%") DO (
    set AHFCMD_DATE=%%~t?
)

FOR %%? IN ("%BASENAME%.AT.XML") DO (
    set AT_XML_DATE=%%~t?
)

if "%AHFCMD_DATE%" GTR "%AT_XML_DATE%" goto at

rem No need to regenerate %BASENAME%.AT.XML
echo %BASENAME%.AT.XML is up to date

goto at_done

:at

echo Analyzing '%FILE%' and generating '%BASENAME%.AT.XML'

if exist %BASENAME%.AT.XML del %BASENAME%.AT.XML
if exist %BASENAME%.AT.XML (
   echo Unable to replace '%BASENAME%.AT.XML'.
   goto error
)

"%AHFCMD%" -analyze -p @AreaTree -xmlerr -d %FILE% %opt% -o %BASENAME%.AT.XML 2> %BASENAME%.log.xml

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when analyzing '%FILE%'. Check log file '%BASENAME%.log.xml'.
   goto error
)

if not exist %BASENAME%.AT.XML (
   echo Area Tree XML file for '%FILE%' was not created. Check log file '%BASENAME%.log.xml'.
   goto error
)

:at_done

if "%format%"=="annotate" (
   goto annotate
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

call :sub_2pdf %PWD%\%BASENAME%.annotated.AT.xml %PWD%\%BASENAME%.annotated.pdf %PWD%\%BASENAME%.annotated.log.txt

if %ERRORLEVEL% NEQ 0 goto error

rem View the PDF
if exist %BASENAME%.annotated.pdf (
   echo Analysis completed.
   echo Annotated PDF: '%BASENAME%.annotated.pdf'
   %BASENAME%.annotated.pdf 
) else (
   echo An error occurred when generating '%BASENAME%.annotated.pdf'. Check log file '%BASENAME%.annotated.log.txt'.
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
   echo '-transformer' is ignored with '-format report'
)

rem Whether or not to regenerate %BASENAME%.pdf...

if "%force%"=="yes" goto report_pdf_do

for /F "usebackq" %%q in (`dir /B /OD %BASENAME%.fo %BASENAME%.pdf`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.pdf" goto report_pdf_do

echo %BASENAME%.pdf is up to date
goto report_pdf_done

:report_pdf_do

call :sub_2pdf %PWD%\%BASENAME%.fo %PWD%\%BASENAME%.pdf %PWD%\%BASENAME%.log.txt "%opt%"

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when generating '%BASENAME%.pdf'. Check log file '%BASENAME%.log.txt'.
   goto error
)

:report_pdf_done

rem Whether or not to regenerate %BASENAME%.report.fo...

for /F "usebackq" %%q in (`dir /B /OD %BASENAME%.fo %BASENAME%.log.xml %BASENAME%.report.fo`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.report.fo" goto report_fo_do

echo %BASENAME%.report.fo is up to date
goto report_fo_done

:report_fo_do

call :sub_on_path java.exe
if "%__SUB_ON_PATH_MATCH%"=="" (
   rem Java is not available.
   echo java.exe must be in a directory on the PATH.
   goto error
)

for %%? in (%BASENAME%.fo) do set FO_DATE=%%~t?

echo Generating '%BASENAME%.report.fo' from '%BASENAME%.AT.xml'
java -jar %LIB_DIR%\saxon9he.jar -s:%PWD:\=/%/%BASENAME%.AT.xml -xsl:%REPORTER_XSLT:\=/% -o:%BASENAME%.report.fo logfile=file:///%PWD%/%BASENAME%.log.xml lang=%lang% file=%PWD:\=/%/%BASENAME%.fo file-date="%FO_DATE%" pdf-file=%PWD:\=/%/%BASENAME%.pdf %xsltparam%

if %ERRORLEVEL% NEQ 0 (
   echo.
   echo An error occurred when creating the report XSL-FO file.
   goto error
)

:report_fo_done


rem Whether or not to regenerate %BASENAME%.report.pdf...

for /F "usebackq" %%q in (`dir /B /OD %BASENAME%.report.fo %BASENAME%.report.pdf`) do (
    set NEWER=%%q
)
rem echo %NEWER%

if not "%NEWER%"=="%BASENAME%.report.pdf" goto report_pdf_do

echo %BASENAME%.report.pdf is up to date
goto report_pdf_done

:report_pdf_do

call :sub_2pdf %PWD%\%BASENAME%.report.fo %PWD%\%BASENAME%.report.pdf %PWD%\%BASENAME%.report.log.txt

if %ERRORLEVEL% NEQ 0 goto error

:report_pdf_done

rem View the PDF
if exist %BASENAME%.report.pdf (
   echo Analysis completed.
   echo Report PDF: '%BASENAME%.report.pdf'
   %BASENAME%.report.pdf 
) else (
   echo An error occurred when generating '%BASENAME%.report.pdf'. Check log file '%BASENAME%.report.log.txt'.
   goto error
)

goto done

rem ----------------------------------------------------------------------
rem Subroutines

:sub_on_path
rem echo %1
set __SUB_ON_PATH_MATCH=%~$PATH:1
exit /B 1

:sub_msxsl
msxsl %BASENAME%.AT.xml %REPORTER_XSLT% -o %BASENAME%.annotated.AT.xml logfile=%PWD%/%BASENAME%.log.xml lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_xsltproc
xsltproc --stringparam logfile %PWD%/%BASENAME%.log.xml --stringparam lang %lang% %xsltparam% -o %BASENAME%.annotated.AT.xml %REPORTER_XSLT% %PWD%/%BASENAME%.AT.xml
exit /B %ERRORLEVEL%

:sub_saxon6
java -jar %LIB_DIR%\saxon.jar -o %BASENAME%.annotated.AT.xml %PWD:\=/%/%BASENAME%.AT.xml %REPORTER_XSLT:\=/% logfile=file:///%PWD%/%BASENAME%.log.xml lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_saxon9
java -jar %LIB_DIR%\saxon9he.jar -s:%PWD:\=/%/%BASENAME%.AT.xml -xsl:%REPORTER_XSLT:\=/% -o:%BASENAME%.report.fo logfile=file:///%PWD%/%BASENAME%.log.xml lang=%lang% %xsltparam%
exit /B %ERRORLEVEL%

:sub_2pdf

set SOURCE=%1
set TARGET=%2
set LOG=%3
set PDF_OPT=%~4

rem If the PDF is open in Acrobat, it can't be either deleted or replaced.
if exist %TARGET% del %TARGET%
if exist %TARGET% (
   echo Unable to replace '%TARGET%'.
   exit /B 1
)

set SOURCE_BASENAME=
for /F  %%I in ("%SOURCE%") do set SOURCE_BASENAME=%%~nxI


set TARGET_BASENAME=
for /F  %%I in ("%TARGET%") do set TARGET_BASENAME=%%~nxI

echo Formatting '%SOURCE_BASENAME%' as '%TARGET_BASENAME%'
rem Use highest-possible PDF version in case embedding high-version PDF
"%AHFCMD%" -x 4 %PDF_OPT% -d %SOURCE% -o %TARGET% 2> %LOG%

if %ERRORLEVEL% NEQ 0 (
   echo An error occurred when generating '%TARGET%'. Check log file '%LOG%'.
   exit /B 1
)
exit /B 0

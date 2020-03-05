#!/bin/sh

#    Copyright 2020 Antenna House, Inc.
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#    implied.
#
#    See the License for the specific language governing permissions and
#    limitations under the License.

if [ "$1" == "" ] ; then
    echo
    echo "Analyze a formatted file and generate annotated PDF"
    echo
    echo "usage: analyzer.sh -d file [-opt \"options\"] [-lang lang] [-ahfcmd AHFCmd]"
    echo "                   [-xslt xslt] [-xsltparam \"xslt-params\" ]"
    echo
    echo "       lang    : Language for error messages -- en or ja"
    echo "       options : Additional AHFCmd command-line parameters"
    echo "       AHFCmd  : Path to AHFCmd.exe"
    echo "       file    : File to format and analyze"
    echo "       xslt    : XSLT stylesheet to use"
    echo "       xslt-params : XSLT processor options and parameters"
    echo

    exit 0
fi

PWD=`pwd`
# From https://stackoverflow.com/a/44644933
# ${ANALYZER_DIR} does not include a trailing '/'.
ANALYZER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
XSL_DIR=${ANALYZER_DIR}/xsl

# From https://stackoverflow.com/a/7948533
# NOTE: This requires GNU getopt.  On Mac OS X and FreeBSD, you have
# to install this separately.
# ':' after '--long' option names indicates that it must be followed
# by a parameter value.
TEMP=`getopt -a -o d: --long lang:,ahfcmd:,opt:,xslt:,xsltparam: \
             -n 'analyzer' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

AHFCMD=
FILE=
LANG=en
OPT=
XSLT=
XSLT_OPT=

while true; do
  case "$1" in
    --ahfcmd ) AHFCMD="$2"; shift 2 ;;
    -d ) FILE="$2"; shift 2 ;;
    --lang ) LANG="$2"; shift 2 ;;
    --opt ) OPT="$2"; shift 2 ;;
    --xslt ) XSLT="$2"; shift 2 ;;
    --xsltparam ) XSLT_OPT="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ "x$FILE" == "x" ] ; then
    echo "No source file specified" >&2 ; exit 1
fi
if [ ! -e "$FILE" ] ; then
    echo "Source file does not exist: $FILE" >&2 ; exit 1
fi
if [ ! -s "$FILE" ] ; then
    echo "Source file is empty: $FILE" >&2 ; exit 1
fi
if [ ! -r "$FILE" ] ; then
    echo "Source file is not readable: $FILE" >&2 ; exit 1
fi


if [ "x$AHFCMD" == "x" ] ; then
    if [ "x$AHF70_64_HOME" == "x" ] ; then
	AHF70_64_HOME=/usr/AHFormatterV70_64
    fi

    RUN_SH=${AHF70_64_HOME}/run.sh
else
    if [ ! -e "$AHFCMD" ] ; then
	echo "Formatter file does not exist: $AHFCMD" >&2 ; exit 1
    else
	RUN_SH=$AHFCMD
    fi
fi

if [ "x$XSLT" == "x" ] ; then
    REPORTER_XSLT=${XSL_DIR}/ahfcmd-reporter.xsl
else
    if [ ! -e "$XSLT" ] ; then
	echo "XSLT file does not exist: $XSLT" >&2 ; exit 1
    else
	REPORTER_XSLT=$XSLT
    fi
fi
BASENAME_FO=`basename $FILE .fo`
BASENAME=`basename $BASENAME_FO .html`

# Need '-stdout' because 'run.sh' always echoes AHFCmd command-line to
# STDERR.
"${RUN_SH}" -analyze ${OPT} -p @AreaTree -xmlerr -d $FILE -o ${BASENAME}.AT.xml -stdout > ${BASENAME}.log.xml 2>/dev/null

if [ $? != 0 ] ; then
    echo "An error occurred when analyzing '${FILE}'. Check log file '${BASENAME}.log.xml'." >&2
    exit 1
fi

xsltproc --stringparam logfile ${PWD}/${BASENAME}.log.xml --stringparam lang ${LANG} ${XSLT_OPT} -o ${BASENAME}.annotated.AT.xml ${REPORTER_XSLT} ${PWD}/${BASENAME}.AT.xml

if [ $? != 0 ] ; then
    echo "An error occurred when creating the annotated Area Tree XML file." >&2
    exit 1
fi

if [ -e "${BASENAME}.annotated.pdf" ] && [ ! -w "${BASENAME}.annotated.pdf" ] ; then
    echo "Unable to replace '${BASENAME}.annotated.pdf'." >&2
    exit 1
fi

"${RUN_SH}" -x 4 -d ${BASENAME}.annotated.AT.xml -o ${BASENAME}.annotated.pdf 2> ${BASENAME}.annotated.log.txt

if [ $? != 0 ] ; then
    echo "An error occurred when generating '${BASENAME}.annotated.pdf'. Check log file '${BASENAME}.annotated.log.txt'." >&2
    exit 1
fi

echo Analysis completed.
echo Annotated PDF: ${BASENAME}.annotated.pdf

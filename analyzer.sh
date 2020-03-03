#!/bin/sh
# $Id$

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

AHF70_64_HOME=/usr/AHFormatterV70_64

RUN_SH=${AHF70_64_HOME}/run.sh

REPORTER_XSLT=ahfcmd-reporter.xsl

LANG=en

FILE=$1

BASENAME_FO=`basename $FILE .fo`
BASENAME=`basename $BASENAME_FO .html`

"${RUN_SH}"  -analyze -p @AreaTree -xmlerr -d $FILE -o ${BASENAME}.AT.xml -stdout > ${BASENAME}.log.xml

xsltproc --stringparam logfile ${BASENAME}.log.xml --stringparam lang ${LANG} -o annotated-${BASENAME}.AT.xml ${REPORTER_XSLT} ${BASENAME}.AT.xml

"${RUN_SH}" -x 4 -d annotated-${BASENAME}.AT.xml -o annotated-${BASENAME}.pdf 2> annotated-${BASENAME}.log.txt

echo Analysis completed.
echo Annotated PDF: annotated-${BASENAME}.pdf

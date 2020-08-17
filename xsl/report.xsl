<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY ldquo '&#x201C;' >
<!ENTITY rdquo '&#x201D;' >
<!ENTITY nbsp  '&#xA0;' >
<!ENTITY ndash '&#x2013;' >
<!ENTITY times '&#xD7;' >
]>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    version="3.0"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
    xmlns:ahferr="http://www.antennahouse.com/names/Error"
    xmlns:at="http://www.antennahouse.com/names/XSL/AreaTree"
    xmlns:axf="http://www.antennahouse.com/names/XSL/Extensions"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    exclude-result-prefixes="ahf ahferr array at xs map math">

<!-- Generate XSL-FO for a report on formmating issues in a document. -->

<!--
   Copyright 2020 Antenna House, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->

<!--
     This stylesheet transforms an Area Tree XML file plus its
     associated error log, in XML format, into an XSL-FO file that can
     be formatted to create a report of the analyzer errors in the
     formatted document that the Area Tree XML file represents.

     Wherever it has been practical to do so, the template rules are
     'decomposed' into named templates and stylesheet functions.
     These templates and functions can, and are, used as building
     blocks for alternative report formats.

     This stylesheet makes extensive use of <xsl:attribute-set> for
     much the same reason.
-->

<!-- ============================================================= -->
<!-- IMPORTS                                                       -->
<!-- ============================================================= -->

<!-- Functions used by multiple Antenna House stylesheets. -->
<xsl:import href="ahf-common.xsl"/>

<!-- Functions for working with lengths. -->
<xsl:import href="ahf-unit-conversions.xsl"/>

<!-- Lookup of localized string. -->
<xsl:import href="ahf-l10n.xsl"/>


<!-- ============================================================= -->
<!-- xsl:strip-space                                               -->
<!-- ============================================================= -->

<!-- AH Formatter does not generate white-space between elements, but
     the source file may have been re-indented in an editor. -->
<xsl:strip-space elements="at:*" />


<!-- ============================================================= -->
<!-- KEYS                                                          -->
<!-- ============================================================= -->

<!-- No keys. -->


<!-- ============================================================= -->
<!-- OUTPUT                                                        -->
<!-- ============================================================= -->

<xsl:output indent="no" />

<!-- ============================================================= -->
<!-- DEFAULT MODE                                                  -->
<!-- ============================================================= -->

<xsl:mode use-accumulators="#all" />


<!-- ============================================================= -->
<!-- STYLESHEET PARAMETERS                                         -->
<!-- ============================================================= -->

<!-- Whether to generate verbose error messages. -->
<xsl:param name="verbose" select="false()" as="xs:boolean"
           static="yes" />

<!-- Whether to generate verbose error messages. -->
<xsl:param name="debug" select="false()" as="xs:boolean"
           static="yes" />

<!-- File name to report as source file. -->
<xsl:param name="file" select="base-uri(.)" as="xs:string" />

<!-- File name to report as source file. -->
<xsl:param name="file-date" as="xs:string?" static="yes" />

<!-- PDF file from which to extract page images. -->
<xsl:param name="pdf-file" as="xs:string" />

<!-- Language of messages in report output. -->
<xsl:param name="lang" select="'en'" />

<!-- For 'ahf-l10n.xsl'. -->
<xsl:param name="default-lang" select="'en'" static="yes" />

<!-- Error code numbers for analysis errors. -->
<xsl:param name="error-codes" select="45953 to 45961"
           as="xs:integer+" static="yes" />

<xsl:param name="logfile" />

<!-- Maximum number of page images to try to keep on first summary
     page. -->
<xsl:param name="summary-page-keep-limit" select="'700'"
           as="xs:string" static="yes" />

<!-- Output page size. -->
<xsl:param name="page-width" select="'297mm'" as="xs:string"
           static="yes" />
<xsl:param name="page-height" select="'210mm'" as="xs:string"
           static="yes" />
<xsl:param name="page-margin" select="'11mm'" as="xs:string"
           static="yes" />
<xsl:param name="body-column-count" select="2" as="xs:integer"
           static="yes" />
<xsl:param name="body-column-gap" select="'19mm'" as="xs:string"
           static="yes" />


<!-- ============================================================= -->
<!-- GLOBAL VARIABLES                                              -->
<!-- ============================================================= -->

<!-- Width of border around the image of a page. -->
<xsl:variable name="page-image-border-width" select="'0.5mm'"
              static="yes" />

<!-- Width of border around an error area. -->
<xsl:variable name="page-image-error-border-width" select="'thin'" />

<!-- Width of border around an error area. -->
<xsl:variable name="page-image-error-border-radius" select="'2pt'" />

<!-- On Windows, path of $logfile may include '\'.  msxsl handles
     either '\' or '/' in document(), but xsltproc has only worked
     with '/'. -->
<xsl:variable name="logfile-doc"
              select="doc(translate($logfile, '\', '/'))" />

<!-- Constant text that precedes the location information in an
     analyzer error message. -->
<xsl:variable name="location-marker"
              select="'&#xA;location:: '" static="yes" />


<!-- Variables for error messages found in log file. -->

<!-- Get the errors reported for the Area Tree XML file. -->
<xsl:variable name="errors-doc">
  <!--<xsl:message><xsl:copy-of select="$logfile-doc" /></xsl:message>-->
  <xsl:apply-templates select="$logfile-doc" mode="logfile" />
</xsl:variable>

<!-- Get just the errors. -->
<xsl:variable name="errors" as="element(error)*"
              select="$errors-doc/errors/error" />

<!-- Only the error codes found in the log file, sorted by error
     code. -->
<xsl:variable
    name="reported-error-codes" as="xs:string*"
    select="distinct-values($errors[exists(@message)]/@code,
                            'http://www.w3.org/2005/xpath-functions/collation/codepoint')" />

<!-- Variables for page dimensions. -->

<xsl:variable
    name="page-image-margin-left"
    select="ahf:mm(($page-width,
                    '-', $page-margin,
                    '-', $page-margin,
                    $body-column-gap)) div $body-column-count"
    as="xs:double" />
<xsl:variable
    name="page-image-available-width"
    select="ahf:mm(($page-width,
                    '-', $page-margin,
                    '-', $page-margin,
                    '-', $body-column-gap)) div 2
            (:- ahf:mm(($page-image-border-width,
                        $page-image-border-width)):)"
    as="xs:double" />
<xsl:variable
    name="page-image-available-height"
    select="ahf:mm(($page-height,
                    '-', $page-margin,
                    '-', $page-margin(:,
                    '-', $page-image-border-width,
                    '-', $page-image-border-width:)))"
    as="xs:double" />

<!-- Sequence of colors to use for thumbnail borders.  Colors are used
     to indicate severity, from least number or severity of errors to
     greatest number or severity. -->
<xsl:variable name="thumbnail-colors" as="element(color)+">
  <color border="rgba(100%, 0%, 0%, 0.4)" />
  <color border="rgba(100%, 0%, 0%, 0.55)" />
  <color border="rgba(100%, 0%, 0%, 0.7)" />
  <color border="rgba(100%, 0%, 0%, 0.8)" />
  <color border="rgba(100%, 0%, 0%, 0.9)" />
  <color border="rgba(100%, 0%, 0%, 1.0)" />
</xsl:variable>

<!-- The hues of these colors are equally spaced but the colors are
     not in sequence of hue angle. -->
<xsl:variable name="callout-colors" as="element(color)+">
  <!-- Reddish. -->
  <color border="hsla(0, 100%, 54%, 0.5)" color="hsl(0, 100%, 54%)" />
  <!-- Blue. -->
  <color border="hsla(210, 100%, 54%, 0.5)" color="hsl(210, 100%, 54%)" />
  <!-- Orangey. -->
  <color border="hsla(30, 100%, 54%, 0.5)" color="hsl(30, 100%, 54%)" />
  <!-- Light green. -->
  <color border="hsla(120, 100%, 54%, 0.5)" color="hsl(120, 100%, 54%)" />
  <!-- Darker blue. -->
  <color border="hsla(240, 100%, 54%, 0.5)" color="hsl(240, 100%, 54%)" />
  <!-- Pinkish. -->
  <color border="hsla(300, 100%, 54%, 0.5)" color="hsl(300, 100%, 54%)" />
  <!-- Light green-blue. -->
  <color border="hsla(150, 100%, 54%, 0.5)" color="hsl(150, 100%, 54%)" />
  <!-- Magenta-ish. -->
  <color border="hsla(270, 100%, 54%, 0.5)" color="hsl(270, 100%, 54%)" />
  <!-- Yellow-green. -->
  <color border="hsla(90, 100%, 54%, 0.5)" color="hsl(90, 100%, 54%)" />
  <!-- Light blue. -->
  <color border="hsla(180, 100%, 54%, 0.5)" color="hsl(180, 100%, 54%)" />
  <!-- Pinkish red. -->
  <color border="hsla(330, 100%, 54%, 0.5)" color="hsl(330, 100%, 54%)" />
  <!-- Yellow is too pale. -->
  <!--
  <color border="hsla(60, 100%, 54%, 0.5)" color="hsl(60, 100%, 54%)" />
  -->
</xsl:variable>

<!-- ============================================================= -->
<!-- ATTRIBUTE SETS                                                -->
<!-- ============================================================= -->

<!-- Ordered alphabetically. -->

<xsl:attribute-set name="document-defaults">
  <xsl:attribute name="font-family"
                 select="'sans-serif, ''MS PGothic'''" />
</xsl:attribute-set>

<xsl:attribute-set name="error-label">
  <xsl:attribute name="keep-together.within-line"
                 select="'always'" />
  <xsl:attribute name="axf:number-transform"
                 select="'filled-circled-decimal'" />
</xsl:attribute-set>

<xsl:attribute-set name="footer">
  <xsl:attribute name="font-size"
                 select="'0.75rem'" />
  <xsl:attribute name="color" select="'grey'" />
</xsl:attribute-set>

<xsl:attribute-set name="page-error-list.list-block">
  <xsl:attribute name="provisional-distance-between-starts"
                 select="'1.5em'" />
  <xsl:attribute name="provisional-label-separation"
                 select="'0.5em'" />
  <xsl:attribute name="space-before" select="'0.5lh'" />
  <xsl:attribute name="space-after" select="'0.5lh'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item">
  <xsl:attribute name="keep-together.within-column" select="'always'" />
  <xsl:attribute name="margin-left" select="'0'" />
  <xsl:attribute name="space-before" select="'0.5lh'" />
  <xsl:attribute name="space-after" select="'0.5lh'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item-body">
  <xsl:attribute name="start-indent" select="'body-start()'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item-label">
  <xsl:attribute name="end-indent" select="'label-end()'" />
</xsl:attribute-set>

<xsl:attribute-set name="per-page-image.block-container">
</xsl:attribute-set>

<xsl:attribute-set name="per-page-title">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="font-size" select="'1.5em'" />
  <xsl:attribute name="keep-with-next.within-column" select="'always'" />
  <xsl:attribute name="width" select="'100%'" />
</xsl:attribute-set>

<xsl:attribute-set name="section-title">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="space-before" select="'1rlh'" />
  <xsl:attribute name="keep-with-next" select="'always'" />
</xsl:attribute-set>

<xsl:attribute-set name="summary-table" use-attribute-sets="table">
  <xsl:attribute name="keep-together.within-column" select="1" />
  <xsl:attribute name="text-align" select="'center'" />
</xsl:attribute-set>

<xsl:attribute-set name="table">
  <xsl:attribute name="space-before" select="'0.5lh'" />
  <xsl:attribute name="space-after" select="'0.5lh'" />
  <xsl:attribute name="border-collapse"
                 select="'collapse-with-precedence'" />
  <xsl:attribute name="border-top" select="'1pt solid grey'" />
  <xsl:attribute name="border-bottom" select="'1pt solid grey'" />
  <xsl:attribute name="axf:border-connection-form" select="'precedence'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-caption">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="font-size" select="'1.2em'" />
  <xsl:attribute name="padding" select="'0.4em'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-cell">
  <xsl:attribute name="padding" select="'0.4em'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-cell-number"
                   use-attribute-sets="table-cell">
  <xsl:attribute name="text-align" select="'right'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-column">
  <xsl:attribute name="border-right" select="'1.5pt solid white'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-head-cell"
                   use-attribute-sets="table-cell">
  <xsl:attribute name="background-color" select="'lightgray'" />
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="axf:pdftag" select="'TH'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-header">
  <xsl:attribute name="border-bottom" select="'1pt solid grey'" />
  <xsl:attribute name="border-after-precedence" select="'10'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-row">
  <xsl:attribute name="border-bottom" select="'0.5pt solid gray'" />
  <xsl:attribute name="border-top" select="'0.5pt solid gray'" />
</xsl:attribute-set>

<xsl:attribute-set name="title" use-attribute-sets="section-title">
  <xsl:attribute name="font-size" select="'1.2em'" />
  <xsl:attribute name="text-align" select="'center'" />
  <xsl:attribute name="space-after" select="'0.5em'" />
  <xsl:attribute name="keep-with-next" select="'always'" />
</xsl:attribute-set>


<!-- ============================================================= -->
<!-- TEMPLATES                                                     -->
<!-- ============================================================= -->

<xsl:template match="/">
  <!-- Evaluate accumulators only.  There are no templates that match
       Area Tree XML elements and no text nodes in the Area Tree XML,
       so nothing is added to the result. -->
  <xsl:apply-templates />

  <!-- Accumulator values. -->
  <xsl:variable name="all-pages-info"
                select="accumulator-after('all-pages-info')"
                as="array(array(item()))" />

  <xsl:variable name="odd-pages-left"
                select="accumulator-after('odd-pages-left')"
                as="xs:boolean" />

  <xsl:call-template name="root">
    <xsl:with-param name="all-pages-info"
                    select="$all-pages-info"
                    as="array(array(item()))"
                    tunnel="yes" />
    <xsl:with-param name="odd-pages-left"
                    select="$odd-pages-left"
                    as="xs:boolean"
                    tunnel="yes" />
  </xsl:call-template>
</xsl:template>


<!-- ============================================================= -->
<!-- 'logfile' MODE                                                -->
<!-- ============================================================= -->

<xsl:template match="/" mode="logfile">
  <errors>
    <xsl:text>&#xA;</xsl:text>
    <xsl:apply-templates mode="logfile" />
  </errors>
</xsl:template>

<!-- Process child <ahferr:error> elements. -->
<xsl:template match="ahferr:errors" mode="logfile">
  <xsl:apply-templates mode="logfile" />
</xsl:template>

<!-- Process only errors within the range of error codes for analysis
     errors. -->
<!-- Variable references are not allowed in match patterns in XSLT
     1.0, so it is necessary to hardcode the minimum and maximum
     decimal error codes here. (The alternative woud be to
     autogenerate this XSLT file, but we're not there yet.) -->
<!-- **** UPDATE MINIMUM AND MAXIMUM TO MATCH AH FORMATTER **** -->
<xsl:template
    match="ahferr:error[@code >= $error-codes[1] and
                        @code &lt;= $error-codes[last()]]"
    mode="logfile"
    xmlns="">

  <xsl:variable name="error-code" select="@code" />
  <!--<xsl:message><xsl:value-of select="." /></xsl:message>-->
  <error code="{$error-code}">
    <xsl:if test="normalize-space(
                    substring-before(., $location-marker)) != ''">
      <xsl:attribute
          name="message">
        <xsl:value-of
            select="normalize-space(substring-before(.,
                                                     $location-marker))" />
      </xsl:attribute>
    </xsl:if>
    <xsl:call-template name="make-attributes">
      <xsl:with-param name="text"
                      select="substring-after(., $location-marker)" />
    </xsl:call-template>
  </error>
  <xsl:text>&#xA;</xsl:text>
</xsl:template>


<!-- ============================================================= -->
<!-- NAMED TEMPLATES                                               -->
<!-- ============================================================= -->

<xsl:template name="root">
  <fo:root xsl:use-attribute-sets="document-defaults">
    <xsl:call-template name="layer-settings" />
    <xsl:call-template name="layout-master-set" />
    <xsl:call-template name="declarations" />
    <xsl:call-template name="report-summary" />
    <xsl:call-template name="page-reports" />
  </fo:root>
</xsl:template>

<!-- Add axf:layer-settings to fo:root. -->
<xsl:template name="layer-settings" as="attribute(axf:layer-settings)">
  <xsl:attribute name="axf:layer-settings">
    <xsl:for-each select="$reported-error-codes">
      <xsl:sort select="ahf:l10n(.)" />
      <xsl:sequence select="if (position() > 1) then ', ' else ()" />
      <xsl:value-of select="concat('&quot;', ahf:l10n(.), '&quot;')" />
    </xsl:for-each>
  </xsl:attribute>
</xsl:template>

<xsl:template name="layout-master-set">
  <fo:layout-master-set>
    <fo:simple-page-master
        master-name="summary"
        page-width="{$page-width}" page-height="{$page-height}"
        margin="{$page-margin}">
      <fo:region-body column-count="{$body-column-count}"
                      column-gap="{$body-column-gap}" />
      <fo:region-after padding-top="0.5em" />
    </fo:simple-page-master>
    <fo:simple-page-master
        master-name="page-first"
        page-width="{$page-width}" page-height="{$page-height}"
        margin="{$page-margin}">
      <fo:region-body
          margin-left="{$page-image-margin-left}mm" />
      <fo:region-body
          region-name="page-image"
          margin-right="{ahf:mm(($page-width,
                                 '-', $page-margin,
                                 '-', $page-margin,
                                 $body-column-gap)) div 2}mm" />
      <fo:region-after padding-top="0.5em" />
    </fo:simple-page-master>
    <fo:simple-page-master
        master-name="page-rest"
        page-width="{$page-width}" page-height="{$page-height}"
        margin="{$page-margin}">
      <fo:region-body
          column-count="{$body-column-count}"
          column-gap="{$body-column-gap}" />
      <fo:region-after extent="{$page-margin}"
                       padding-top="0.5em" />
    </fo:simple-page-master>
    <fo:page-sequence-master master-name="page-pages">
      <fo:repeatable-page-master-alternatives>
        <fo:conditional-page-master-reference
            page-position="first"
            master-reference="page-first" />
        <fo:conditional-page-master-reference
            master-reference="page-rest" />
      </fo:repeatable-page-master-alternatives>
    </fo:page-sequence-master>
  </fo:layout-master-set>
</xsl:template>

<xsl:template name="declarations">
  <fo:declarations>
    <axf:document-info
        name="document-title"
        value="{if (exists(at:AreaRoot/@document-info.document-title))
                  then string-join(('AH Formatter Analysis Report for ‘',
                                    at:AreaRoot/@document-info.document-title,
                                    '’ (',
                                    ahf:basename($file),
                                    ')'),
                                   '')
                else string-join((ahf:l10n('AH Formatter Analysis Report'),
                                  ' - ',
                                  ahf:basename($file)),
                                  '')}" />
    <axf:document-info
        name="displaydoctitle"
        value="true" />
    <axf:document-info
        name="fitwindow"
        value="true" />
  </fo:declarations>
</xsl:template>

<xsl:template name="report-summary">
  <xsl:param name="all-pages-info"
             select="accumulator-after('all-pages-info')"
             as="array(array(item()))"
             tunnel="yes" />

  <fo:page-sequence master-reference="summary" id="summary">
    <fo:flow flow-name="xsl-region-body">
      <xsl:call-template name="title-and-summary" />
      <xsl:call-template name="page-thumbnails" />
    </fo:flow>
  </fo:page-sequence>
</xsl:template>

<xsl:template name="title-and-summary">
  <xsl:param name="all-pages-info"
             select="accumulator-after('all-pages-info')"
             as="array(array(item()))"
             tunnel="yes" />

  <fo:block xsl:use-attribute-sets="title">
    <xsl:value-of select="ahf:l10n('AH Formatter Analysis Report')" />
  </fo:block>
  <fo:table width="100%" xsl:use-attribute-sets="table">
    <fo:table-column xsl:use-attribute-sets="table-column" />
    <fo:table-body>
      <xsl:if test="exists(at:AreaRoot/@document-info.document-title)">
        <fo:table-row xsl:use-attribute-sets="table-row">
          <fo:table-cell xsl:use-attribute-sets="table-head-cell">
            <fo:block>
              <xsl:value-of select="ahf:l10n('Title')" />
            </fo:block>
          </fo:table-cell>
          <fo:table-cell xsl:use-attribute-sets="table-cell">
            <fo:block>
              <xsl:value-of select="at:AreaRoot/@document-info.document-title" />
            </fo:block>
          </fo:table-cell>
        </fo:table-row>
      </xsl:if>
      <fo:table-row xsl:use-attribute-sets="table-row">
        <fo:table-cell xsl:use-attribute-sets="table-head-cell">
          <fo:block>
            <xsl:value-of select="ahf:l10n('File')" />
          </fo:block>
        </fo:table-cell>
        <fo:table-cell xsl:use-attribute-sets="table-cell">
          <fo:block>
            <xsl:value-of select="$file" />
          </fo:block>
        </fo:table-cell>
      </fo:table-row>
      <xsl:if test="exists($file-date)">
        <fo:table-row xsl:use-attribute-sets="table-row">
          <fo:table-cell xsl:use-attribute-sets="table-head-cell">
            <fo:block>
              <xsl:value-of select="ahf:l10n('Modification date')" />
            </fo:block>
          </fo:table-cell>
          <fo:table-cell xsl:use-attribute-sets="table-cell">
            <fo:block>
              <xsl:value-of select="$file-date" />
            </fo:block>
          </fo:table-cell>
        </fo:table-row>
      </xsl:if>
      <fo:table-row xsl:use-attribute-sets="table-row">
        <fo:table-cell xsl:use-attribute-sets="table-head-cell">
          <fo:block>
            <xsl:value-of select="ahf:l10n('Pages')" />
          </fo:block>
        </fo:table-cell>
        <fo:table-cell xsl:use-attribute-sets="table-cell">
          <fo:block>
            <xsl:value-of
                select="format-number(array:size($all-pages-info),
                                      '#,###')" />
          </fo:block>
        </fo:table-cell>
      </fo:table-row>
      <fo:table-row xsl:use-attribute-sets="table-row">
        <fo:table-cell xsl:use-attribute-sets="table-head-cell">
          <fo:block>
            <xsl:value-of select="ahf:l10n('Errors')" />
          </fo:block>
        </fo:table-cell>
        <fo:table-cell xsl:use-attribute-sets="table-cell">
          <fo:block>
            <xsl:value-of
                select="format-number(count($errors[exists(@message)]),
                                      '#,###')" />
          </fo:block>
          <xsl:if test="exists($errors[exists(@message)])">
            <fo:table width="100%" xsl:use-attribute-sets="table">
              <fo:table-column xsl:use-attribute-sets="table-column" />
              <fo:table-column xsl:use-attribute-sets="table-column" />
              <fo:table-header xsl:use-attribute-sets="table-header">
                <fo:table-row xsl:use-attribute-sets="table-row">
                  <fo:table-cell xsl:use-attribute-sets="table-head-cell">
                    <fo:block>
                      <xsl:value-of select="ahf:l10n('Error')" />
                    </fo:block>
                  </fo:table-cell>
                  <fo:table-cell xsl:use-attribute-sets="table-head-cell">
                    <fo:block>
                      <xsl:value-of select="ahf:l10n('Count')" />
                    </fo:block>
                  </fo:table-cell>
                  <fo:table-cell xsl:use-attribute-sets="table-head-cell">
                    <fo:block>
                      <xsl:value-of select="ahf:l10n('Pages')" />
                    </fo:block>
                  </fo:table-cell>
                </fo:table-row>
              </fo:table-header>
              <fo:table-body>
                <xsl:for-each select="$reported-error-codes">
                  <xsl:sort select="ahf:l10n(.)" />
                  <fo:table-row xsl:use-attribute-sets="table-row">
                    <fo:table-cell xsl:use-attribute-sets="table-cell">
                      <fo:block>
                        <xsl:value-of select="ahf:l10n(.)" />
                      </fo:block>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="table-cell-number">
                      <fo:block>
                        <xsl:value-of
                            select="format-number(count($errors[@code = current()][exists(@message)]),
                                                  '#,###')" />
                      </fo:block>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="table-cell-number">
                      <fo:block>
                        <xsl:value-of
                            select="format-number(count(distinct-values($errors[@code = current()][exists(@message)]/@page)),
                                                  '#,###')" />
                      </fo:block>
                    </fo:table-cell>
                  </fo:table-row>
                </xsl:for-each>
              </fo:table-body>
            </fo:table>
          </xsl:if>
        </fo:table-cell>
        </fo:table-row>
      <!--
          <fo:table-row xsl:use-attribute-sets="table-row">
          <fo:table-cell xsl:use-attribute-sets="table-head-cell">
          <fo:block>AH Formatter</fo:block>
          </fo:table-cell>
          <fo:table-cell xsl:use-attribute-sets="table-cell">
          <fo:block>
          <xsl:value-of select="normalize-space(substring-before(comment()[1], 'Copyright'))" />
          </fo:block>
          </fo:table-cell>
          </fo:table-row>
      -->
    </fo:table-body>
  </fo:table>
</xsl:template>

<xsl:template name="page-thumbnails">
  <xsl:param name="all-pages-info"
             select="accumulator-after('all-pages-info')"
             as="array(array(item()))"
             tunnel="yes" />

  <fo:block-container orphans="1" widows="1" space-before="1em"
                      keep-with-previous.within-page="always">
    <!--
        <xsl:if test="array:size($all-pages-info) &lt;=
        xs:integer($summary-page-keep-limit) and 0">
        <xsl:attribute name="keep-together.within-page"
        select="'always'" />
        <xsl:attribute name="overflow" select="'condense'" />
        <xsl:attribute name="axf:overflow-condense"
        select="'font-size'" />
        </xsl:if>
    -->
    <fo:block text-depth="0">
      <xsl:for-each
          select="1 to array:size($all-pages-info)">
        <xsl:variable
            name="abs-page-number"
            select="xs:string(.)"
            as="xs:string" />
        <xsl:variable
            name="error-count"
            select="count($errors-doc/errors/error[@page = $abs-page-number])"
            as="xs:integer" />
        <xsl:variable
            name="has-errors"
            select="$error-count > 0"
            as="xs:boolean" />
        <xsl:variable
            name="thumbnail-border-color"
            select="ahf:thumbnail-border-color($error-count)"
            as="xs:string" />
        <xsl:variable
            name="page-block"
            select="$all-pages-info(.)"
            as="array(item())" />
        <xsl:variable
            name="page-info"
            select="$page-block(1)"
            as="array(xs:string)" />
        <xsl:variable
            name="this-page-width"
            select="ahf:mm($page-info(4))"
            as="xs:double" />
        <xsl:variable
            name="this-page-height"
            select="ahf:mm($page-info(5))"
            as="xs:double" />

        <xsl:if test="position() != 1">
          <xsl:text> </xsl:text>
        </xsl:if>

        <xsl:choose>
          <xsl:when test="$has-errors">
            <xsl:variable
                name="messages"
                select="$errors-doc/errors/error[@page = $abs-page-number]/
                          @message[normalize-space() ne '']"
                as="xs:string*" />
            <xsl:variable
                name="tooltip">
              <xsl:value-of
                  select="ahf:page-n-m($page-info)" />
              <xsl:for-each
                  select="distinct-values(for $message in $messages
                                            return replace($message,
                                                           '^([^:]+).*',
                                                           '$1'))">
                <xsl:sort
                    select="count($messages[starts-with(., current())])"
                    order="descending" />
                <xsl:sort />
                <xsl:text>&#xA;</xsl:text>
                <xsl:value-of
                    select="count($messages[starts-with(., current())])" />
                <xsl:text> &times; </xsl:text>
                <xsl:value-of
                    select="ahf:l10n(.)" />
              </xsl:for-each>
            </xsl:variable>
            <axf:form-field
                field-type="button"
                axf:field-description="{$tooltip}"
                internal-destination="__report_page_{$abs-page-number}"
                action-type="goto"
                border="{$page-image-border-width} solid {$thumbnail-border-color}">
              <fo:external-graphic
                  src="{$pdf-file}#page={.}"
                  border="0.5pt solid silver"
                  alignment-baseline="after-edge"
                  max-height="2em"
                  max-width="2em" />
            </axf:form-field>
          </xsl:when>
          <xsl:otherwise>
            <axf:form-field
                field-type="button"
                axf:field-description="{ahf:page-n-m($page-info)}"
                border="{$page-image-border-width} solid {$thumbnail-border-color}">
              <fo:external-graphic
                  src="{$pdf-file}#page={.}"
                  border="0.5pt solid silver"
                  alignment-baseline="after-edge"
                  max-height="2em"
                  max-width="2em" />
              </axf:form-field>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </fo:block>
  </fo:block-container>
</xsl:template>

<xsl:template name="page-reports">
  <xsl:param name="all-pages-info"
             select="accumulator-after('all-pages-info')"
             as="array(array(item()))"
             tunnel="yes" />

  <xsl:for-each
      select="1 to array:size($all-pages-info)">
    <xsl:variable
        name="abs-page-number"
        select="xs:string(.)"
        as="xs:string" />
    <xsl:variable
        name="page-block"
        select="$all-pages-info(.)"
        as="array(item())" />
    <xsl:variable
        name="page-info"
        select="$page-block(1)"
        as="array(xs:string)" />
    <xsl:if
        test="exists($errors-doc/errors/error[@page = $abs-page-number])">
    <fo:page-sequence master-reference="page-pages">
      <fo:static-content flow-name="xsl-region-after"
                         xsl:use-attribute-sets="footer">
        <fo:block>
          <xsl:value-of select="$file" />
          <xsl:if test="exists($file-date)">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="$file-date" />
            <xsl:text>)</xsl:text>
          </xsl:if>
        </fo:block>
      </fo:static-content>
      <fo:flow flow-name="xsl-region-body">
        <xsl:call-template name="per-page-title">
          <xsl:with-param
              name="page-info" select="$page-info"
              as="array(xs:string)" tunnel="yes" />
          <xsl:with-param
              name="abs-page-number" select="$abs-page-number"
              as="xs:string" tunnel="yes" />
        </xsl:call-template>
          <!--<xsl:text>Page </xsl:text>
          <xsl:number
              value="$page-info(2)"
              format="{$page-info(3)}" />
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$abs-page-number" />
          <xsl:text>)</xsl:text>-->
        <xsl:call-template name="page-error-list">
          <xsl:with-param
              name="page-errors"
              select="$errors-doc/errors/error[@page = $abs-page-number]
                                              [normalize-space(@message) ne '']"
              as="element(error)*"
              tunnel="yes" />
          <xsl:with-param
              name="abs-page-number" select="$abs-page-number"
              as="xs:string" tunnel="yes" />
        </xsl:call-template>
      </fo:flow>
      <fo:flow flow-name="page-image">
        <xsl:call-template name="per-page-image">
          <xsl:with-param
              name="page-info" select="$page-info"
              as="array(xs:string)" tunnel="yes" />
          <xsl:with-param
              name="page-errors"
              select="$errors-doc/errors/error[@page = $abs-page-number]
                                              [normalize-space(@message) ne '']"
              as="element(error)*"
              tunnel="yes" />
          <xsl:with-param
              name="abs-page-number" select="$abs-page-number"
              as="xs:string" tunnel="yes" />
        </xsl:call-template>
      </fo:flow>
    </fo:page-sequence>
  </xsl:if>
</xsl:for-each>

</xsl:template>

<xsl:template name="per-page-title">
  <xsl:param name="abs-page-number" as="xs:string" tunnel="yes" />
  <xsl:param name="page-info" as="array(xs:string)" tunnel="yes" />

  <fo:block id="__report_page_{$abs-page-number}"
            xsl:use-attribute-sets="per-page-title">
    <xsl:value-of select="ahf:page-n-m($page-info)" />
  </fo:block>
</xsl:template>

<xsl:template name="page-error-list">
  <xsl:param name="page-errors" as="element(error)*" tunnel="yes"
             required="yes" />
  <xsl:param name="abs-page-number" as="xs:string" tunnel="yes"
             required="yes" />
  <xsl:param name="item-number-offset" select="0" as="xs:integer"
             tunnel="yes" />

  <!--<xsl:message select="$page-errors" />-->
  <fo:list-block xsl:use-attribute-sets="page-error-list.list-block">
    <xsl:for-each-group
        select="$page-errors"
        group-adjacent="@message">
      <xsl:variable
          name="use-position"
          select="count($page-errors[. &lt;&lt; current()][exists(@message)]) + 1"
          as="xs:integer" />
      <!--<xsl:message select="count(current-group())" />-->
      <fo:list-item xsl:use-attribute-sets="list-item"
                    axf:layer="{ahf:l10n(@code)}">
        <fo:list-item-label
            xsl:use-attribute-sets="error-label list-item-label">
          <fo:block>
            <xsl:choose>
              <xsl:when test="count(current-group()) = 1">
                <xsl:sequence
                    select="ahf:callout-to($abs-page-number,
                                           $use-position,
                                           $item-number-offset)" />
              </xsl:when>
              <!-- Circled digits up to 20 are available.  Above 20,
                   two or more digit characters are used, which take
                   more space than circled digits. -->
              <xsl:when test="count(current-group()) = (2, 3) and
                              $use-position + count(current-group()) - 1 + $item-number-offset &lt;= 20">
                <xsl:attribute
                    name="end-indent"
                    select="string-join(('label-end() - ',
                                         count(current-group()) - 1,
                                         'em'),
                                        '')" />
                <xsl:for-each select="0 to (count(current-group()) - 1)">
                  <xsl:sequence
                      select="ahf:callout-to($abs-page-number,
                                             $use-position + .,
                                             $item-number-offset)" />
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute
                    name="end-indent"
                    select="'label-end() - 3em'" />
                <xsl:sequence
                    select="ahf:callout-to($abs-page-number,
                                           $use-position,
                                           $item-number-offset)" />
                <xsl:for-each
                    select="$use-position + 1 to
                              $use-position + count(current-group()) - 2">
                  <fo:wrapper
                      id="_to_{ahf:error-id($abs-page-number, .)}" />
                </xsl:for-each>
                <xsl:value-of
                    select="ahf:l10n('page-range-separator')" />
                 <xsl:sequence
                      select="ahf:callout-to($abs-page-number,
                                             $use-position + count(current-group()) - 1,
                                             $item-number-offset)" />
              </xsl:otherwise>
            </xsl:choose>
          </fo:block>
        </fo:list-item-label>
        <fo:list-item-body
            xsl:use-attribute-sets="list-item-body"
            text-indent="{if (count(current-group()) = 1) then '0'
                          else if (count(current-group()) = 2 and
                                   $use-position + count(current-group()) - 1 + $item-number-offset &lt;= 20)
                            then '1em'
                          else if (count(current-group()) = 3 and
                                   $use-position + count(current-group()) - 1 + $item-number-offset &lt;= 20)
                            then '2em'
                          else if ($use-position + $item-number-offset + count(current-group()) - 1 >= 100)
                            then '3em'
                          else '2em'}">
          <fo:block>
            <xsl:value-of
                select="ahf:message-l10n(@message)" />
          </fo:block>
        </fo:list-item-body>
      </fo:list-item>
    </xsl:for-each-group>
  </fo:list-block>
</xsl:template>

<xsl:template name="per-page-image">
  <xsl:param name="page-info" as="array(xs:string)" tunnel="yes" />
  <xsl:param name="abs-page-number" as="xs:string" tunnel="yes" />
  <xsl:param name="page-image-available-width" as="xs:double"
             select="$page-image-available-width" tunnel="yes" />
  <xsl:param name="page-image-available-height" as="xs:double"
             select="$page-image-available-height" tunnel="yes" />
  <xsl:param name="item-number-offset" select="0" as="xs:integer"
             tunnel="yes" />

  <xsl:variable
      name="this-page-width"
      select="ahf:mm($page-info(4))"
      as="xs:double" />
  <xsl:variable
      name="this-page-height"
      select="ahf:mm($page-info(5))"
      as="xs:double" />
  <xsl:variable
      name="page-scale"
      select="min(($page-image-available-width div $this-page-width,
                   $page-image-available-height div $this-page-height,
                   1))"
      as="xs:double" />
  <fo:block-container
      xsl:use-attribute-sets="per-page-image.block-container">
    <fo:block-container z-index="2" position="absolute" width="100%" height="1.5em" xsl:use-when="$debug">
      <fo:block>
        <xsl:value-of
            select="format-number($this-page-width, '0.#'),
                    format-number($this-page-height,'0.#'),
                    $page-image-available-width,
                    $page-image-available-height,
                    format-number($page-scale, '0.####'),
                    format-number($page-image-available-width div $this-page-width, '0.####'),
                    format-number($page-image-available-height div $this-page-height, '0.####')" />
      </fo:block>
    </fo:block-container>
    <fo:block-container
        height="{format-number($this-page-height * $page-scale + 1,
                               '0.####')}mm">
      <fo:block text-depth="0" line-height="0" font-size="0"
                margin-top="-{$page-image-border-width}"
                margin-left="-{$page-image-border-width}">
        <fo:external-graphic
            src="{$pdf-file}#page={$abs-page-number}"
            border="{$page-image-border-width} solid silver"
            max-height="100%"
            max-width="100% - {$page-image-border-width}"
            content-height="{format-number($this-page-height * $page-scale + 1,
                                           '0.####')}mm" />
     </fo:block>
  </fo:block-container>
  <xsl:for-each-group
      select="$errors-doc/errors/error[@page = $abs-page-number]"
      group-starting-with="*[normalize-space(@message) ne '']">
    <xsl:variable name="group-position"
                  select="position()" />
    <xsl:for-each select="current-group()">
      <xsl:variable
          name="use-position"
          select="$group-position + $item-number-offset"
          as="xs:integer" />
      <!-- Extent of error region. -->
      <fo:block-container
          axf:layer="{ahf:l10n(@code)}"
          position="absolute"
          left="{concat(@ax * $page-scale, 'pt')}"
          top="{concat(@ay * $page-scale, 'pt')}"
          width="{concat((@bx - @ax) * $page-scale, 'pt')}"
          height="{concat((@by - @ay) * $page-scale, 'pt')}"
          border-color="{ahf:border-color($use-position)}"
          border-style="solid"
          border-width="{$page-image-error-border-width}"
          axf:border-radius="{$page-image-error-border-radius}"/>
      <!-- Numbered callout only if @message. -->
      <xsl:if test="normalize-space(@message) ne ''">
        <xsl:variable
            name="left-offset-key"
            select="string-join(('report-', @code, '-left'), '')"
            as="xs:string" />
        <xsl:variable
            name="left-offset"
            select="if (not(ahf:l10n($left-offset-key) = $left-offset-key))
                      then ahf:l10n($left-offset-key)
                    else '0pt'"
            as="xs:string" />
        <xsl:variable
            name="top-offset-key"
            select="string-join(('report-', @code, '-top'), '')"
            as="xs:string" />
        <xsl:variable
            name="top-offset"
            select="if (not(ahf:l10n($top-offset-key) = $top-offset-key))
                      then ahf:l10n($top-offset-key)
                    else '0pt'"
            as="xs:string" />
        <fo:block-container
            axf:layer="{ahf:l10n(@code)}"
            position="absolute" width="2em" height="2em"
            left="{concat(@ax * $page-scale, 'pt')} + {$left-offset}"
            top="{concat(@ay * $page-scale, 'pt')} + {$top-offset}">
          <!--<fo:float axf:float="right page" clear="both">-->
          <fo:block
              id="{ahf:error-id($abs-page-number, $group-position)}"
              xsl:use-attribute-sets="error-label"
              color="{ahf:color($use-position)}">
            <axf:form-field
                field-type="button"
                axf:field-description="{ahf:message-l10n(@message)}"
                internal-destination="_to_{ahf:error-id($abs-page-number, $group-position)}"
                action-type="goto">
              <xsl:value-of select="$use-position" />
            </axf:form-field>
          </fo:block><!--</fo:float>-->
        </fo:block-container>
      </xsl:if>
    </xsl:for-each>
  </xsl:for-each-group>
</fo:block-container>
</xsl:template>

<xsl:template name="make-attributes">
  <xsl:param name="text" as="xs:string" />
  <xsl:param name="verbose" select="$verbose" as="xs:boolean" />

  <xsl:if test="$verbose">
    <xsl:message select="'make-attributes:', $text" />
  </xsl:if>
  <xsl:variable name="item" select="substring-before($text, ';')" />
  <xsl:variable name="rest" select="substring-after($text, ';')" />

  <xsl:attribute name="{normalize-space(substring-before($item, ':'))}">
    <xsl:value-of select="normalize-space(substring-after($item, ':'))" />
  </xsl:attribute>

  <xsl:if test="string-length(normalize-space($rest)) > 0">
    <xsl:call-template name="make-attributes">
      <xsl:with-param name="text" select="$rest" as="xs:string" />
      <xsl:with-param name="verbose" select="false()" as="xs:boolean" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- ============================================================= -->
<!-- FUNCTIONS                                                     -->
<!-- ============================================================= -->

<!-- ahf:color($position as xs:integer) as xs:string -->
<!-- Lookup the 'color' value to use for callout numbered $position. -->
<xsl:function name="ahf:color" as="xs:string">
  <xsl:param name="position" as="xs:integer" />

  <xsl:sequence
      select="ahf:color-attribute('color', $position, $callout-colors)" />
</xsl:function>

<!-- ahf:border-color($position as xs:integer) as xs:string -->
<!-- Lookup the 'border-color' value to use for callout numbered
     $position. -->
<xsl:function name="ahf:border-color" as="xs:string">
  <xsl:param name="position" as="xs:integer" />

  <xsl:sequence
      select="ahf:color-attribute('border', $position, $callout-colors)" />
</xsl:function>

<xsl:function name="ahf:color-attribute" as="xs:string">
  <xsl:param name="name" as="xs:string" />
  <xsl:param name="position" as="xs:integer" />
  <xsl:param name="colors" as="element(color)+" />

  <xsl:sequence
      select="$colors[($position - 1) mod count($callout-colors) + 1]/
                @*[local-name() = $name]" />
</xsl:function>

<!-- ahf:error-id($abs-page-number as xs:string, $position as xs:string) as xs:string -->
<!-- Generate a hopefully unique ID for an error indication. -->
<xsl:function name="ahf:error-id" as="xs:string">
  <xsl:param name="abs-page-number" />
  <xsl:param name="position" />

  <xsl:sequence
      select="string-join(('__report_page_',
                           $abs-page-number,
                           '_',
                           $position),
                          '')" />
</xsl:function>

<!-- ahf:thumbnail-border-color($error-count as xs:integer) as xs:string -->
<!-- Generate a color for the border around a thumbnail image of a
     page based on the number of errors on that page. -->
<xsl:function name="ahf:thumbnail-border-color" as="xs:string">
  <xsl:param name="error-count" as="xs:integer" />

  <xsl:sequence
      select="if ($error-count = 0)
                then 'transparent'
              else if ($error-count &lt;= count($thumbnail-colors))
                then ahf:color-attribute('border', $error-count, $thumbnail-colors)
              else ahf:color-attribute('border', count($thumbnail-colors), $thumbnail-colors)" />
</xsl:function>

<!-- ahf:message-10n($message as xs:string) as xs:string -->
<!-- Localize the possibly multiple parts of an analyzer error message. -->
<xsl:function name="ahf:message-l10n" as="xs:string">
  <xsl:param name="message" as="xs:string" />

  <!-- Using xsl:value-of so function returns a single item. -->
  <xsl:value-of>
    <xsl:sequence
        select="ahf:l10n(replace($message,
                                 '^([^:]+).*',
                                 '$1'))" />
    <xsl:if test="contains($message, ':')">
      <xsl:sequence
          select="if (matches($message, '^([^:]+):: '))
                    then ahf:l10n(':: ')
                  else if (matches($message, '^([^:]+): '))
                    then ahf:l10n(': ')
                  else ()" />
      <xsl:analyze-string
          select="replace($message, '^[^:]+:+(.*)', '$1')"
          regex="((;?)\s+)([^:;]+): ">
        <xsl:matching-substring>
          <xsl:sequence
              select="if (regex-group(2) eq ';')
                        then ahf:l10n(';')
                      else (),
                      ' ',
                      ahf:l10n(regex-group(3)),
                      ahf:l10n(': ')" />
          <!--<xsl:message select="regex-group(3)" />-->
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="." />
          <!--<xsl:message select="'No match:', ." />-->
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:if>
  </xsl:value-of>
</xsl:function>

<!-- ahf:callout-to($abs-page-number as xs:string, $position as xs:integer, $offset as xs:integer) as element()+ -->
<!-- Generate a callout link to error $position on page
     $abs-page-number.  Add $offset to $position for visual
     presentation of the link. -->
<xsl:function name="ahf:callout-to" as="element()+">
  <xsl:param name="abs-page-number" as="xs:string" />
  <xsl:param name="position" as="xs:integer" />
  <xsl:param name="offset" as="xs:integer" />
  
  <fo:basic-link
      id="_to_{ahf:error-id($abs-page-number, $position)}"
      internal-destination="{ahf:error-id($abs-page-number, $position)}"
      color="{ahf:color($position + $offset)}">
    <xsl:value-of select="$position + $offset" />
  </fo:basic-link>
</xsl:function>

<xsl:function name="ahf:page-n-m" as="xs:string">
  <xsl:param name="page-info" as="array(xs:string)" />

  <xsl:sequence
      select="if ($page-info(2) = $page-info and
                  $page-info(3) = '1')
                then ahf:l10n('page-n',
                              (format-number(number($page-info(2)),
                                             $page-info(3))))
              else ahf:l10n('page-n-m',
                            (format-number(number($page-info(2)),
                                           $page-info(3)),
                             $page-info(4)))" />
</xsl:function>


<!-- ============================================================= -->
<!-- ACCUMULATORS                                                  -->
<!-- ============================================================= -->

<!-- Absolute and nominal page numbers, page size (incl. crop). -->
<xsl:accumulator
    name="page-info" as="array(xs:string)?"
    initial-value="['0', '0', '0', '0', '0']">
  <xsl:accumulator-rule match="at:PageViewportArea">
    <xsl:sequence
        select="[string(@abs-page-number),
                 string(@page-number),
                 string(@format),
                 concat(ahf:sum-lengths((@width,
                                         @crop-offset-left,
                                         @crop-offset-right)), 'pt'),
                 concat(ahf:sum-lengths((@height,
                                         @crop-offset-top,
                                         @crop-offset-bottom)), 'pt')]" />
  </xsl:accumulator-rule>
</xsl:accumulator>

<!-- Array of arrays of page numbers for a page. -->
<xsl:accumulator name="all-pages-info"
                 as="array(array(item()+))"
    initial-value="[]">
  <xsl:accumulator-rule match="at:PageViewportArea" phase="end">
    <xsl:variable
        name="page-info"
        select="accumulator-after('page-info')"
        as="array(xs:string)" />
    <!-- <xsl:message select="$page-info" /> -->
    <xsl:sequence
        select="array:append($value,
                             [$page-info])" />
  </xsl:accumulator-rule>
</xsl:accumulator>

<!-- Whether the PDF is displayed with odd-numbered pages on the left. -->
<xsl:accumulator name="odd-pages-left"
                 as="xs:boolean"
    initial-value="true()">
  <xsl:accumulator-rule match="at:AreaRoot" phase="start">
    <xsl:sequence
        select="not(@document-info.pagelayout = ('TwoColumnRight',
                                                 'TwoPageRight'))" />
  </xsl:accumulator-rule>
</xsl:accumulator>

</xsl:stylesheet>

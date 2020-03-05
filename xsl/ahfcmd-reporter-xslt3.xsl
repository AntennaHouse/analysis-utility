<?xml version="1.0" encoding="UTF-8"?>
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

<xsl:key name="error-codes" match="error" use="@code" />


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
<xsl:param name="verbose" select="false()" as="xs:boolean" />

<!-- File name to report as source file. -->
<xsl:param name="file" select="base-uri(.)" as="xs:string" />

<!-- File name to report as source file. -->
<xsl:param name="file-date" as="xs:string?" />

<!-- PDF file from which to extract page images. -->
<xsl:param name="pdf-file" as="xs:string" />


<xsl:param name="lang"
           select="'en'" />

<!-- For 'ahf-l10n.xsl'. -->
<xsl:param name="default-lang" select="'en'" />

<!-- Error code numbers for analysis errors. -->
<xsl:param name="error-codes" select="45953 to 45959"
           as="xs:integer+" />

<xsl:param name="logfile" />

<!-- Maximum number of page images to try to keep on first summary
     page. -->
<xsl:param name="summary-page-keep-limit" select="'400'"
           as="xs:string" />

<!-- Output page size. -->
<xsl:param name="page-width" select="'297mm'" as="xs:string" />
<xsl:param name="page-height" select="'210mm'" as="xs:string" />
<xsl:param name="page-margin" select="'11mm'" as="xs:string" />
<xsl:param name="body-column-gap" select="'19mm'" as="xs:string" />

<!-- Width of border around the image of a page. -->
<xsl:variable name="page-image-border-width" select="'0.5mm'" />

<!-- ============================================================= -->
<!-- GLOBAL VARIABLES                                              -->
<!-- ============================================================= -->

<!-- On Windows, path of $logfile may include '\'.  msxsl handles
     either '\' or '/' in document(), but xsltproc has only worked
     with '/'. -->
<xsl:variable name="logfile-doc"
              select="document(translate($logfile, '\', '/'))" />

<xsl:variable name="location-marker"
              select="'&#xA;location:: '" />


<!-- Get the errors in the Area Tree XML file. -->
<xsl:variable name="errors-doc">
  <!--<xsl:message><xsl:copy-of select="$logfile-doc" /></xsl:message>-->
  <xsl:apply-templates select="$logfile-doc" mode="logfile" />
</xsl:variable>

<xsl:variable
    name="page-image-margin-left"
    select="ahf:mm(($page-width,
                    '-', $page-margin,
                    '-', $page-margin,
                    $body-column-gap)) div 2"
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

<!-- Colors are equally spaced but not in sequence of hue angle. -->
<xsl:variable name="colors" as="element(color)+">
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
  <xsl:attribute name="axf:number-transform"
                 select="'filled-circled-decimal'" />
  <xsl:attribute name="color" select="'red'" />
</xsl:attribute-set>

<xsl:attribute-set name="footer">
  <xsl:attribute name="font-size"
                 select="'0.75rem'" />
  <xsl:attribute name="color" select="'grey'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-block">
  <xsl:attribute name="provisional-distance-between-starts"
                 select="'2em'" />
  <xsl:attribute name="provisional-label-separation"
                 select="'0.5em'" />
  <xsl:attribute name="margin-left" select="'-0.5em'" />
  <xsl:attribute name="space-before" select="'0.5em'" />
  <xsl:attribute name="space-after" select="'0.5em'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item">
  <xsl:attribute name="margin-left" select="'0'" />
  <xsl:attribute name="space-before" select="'0.5em'" />
  <xsl:attribute name="space-after" select="'0.5em'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item-body">
  <xsl:attribute name="start-indent" select="'body-start()'" />
</xsl:attribute-set>

<xsl:attribute-set name="list-item-label">
  <xsl:attribute name="end-indent" select="'label-end()'" />
  <xsl:attribute name="text-align" select="'right'" />
</xsl:attribute-set>

<xsl:attribute-set name="per-page-title">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="font-size" select="'1.5em'" />
</xsl:attribute-set>

<xsl:attribute-set name="section-title">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="space-before" select="'1em'" />
  <xsl:attribute name="keep-with-next" select="'always'" />
</xsl:attribute-set>

<xsl:attribute-set name="summary-table" use-attribute-sets="table">
  <xsl:attribute name="keep-together.within-column" select="1" />
  <xsl:attribute name="text-align" select="'center'" />
</xsl:attribute-set>

<xsl:attribute-set name="table">
  <xsl:attribute name="space-before" select="'0.5em'" />
  <xsl:attribute name="space-after" select="'0.5em'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-caption">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="font-size" select="'1.2em'" />
  <xsl:attribute name="padding" select="'0.4em'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-cell">
  <xsl:attribute name="border-bottom" select="'thin solid gray'" />
  <xsl:attribute name="border-top" select="'thin solid gray'" />
  <xsl:attribute name="padding" select="'0.4em'" />
</xsl:attribute-set>

<xsl:attribute-set name="table-head-cell"
                   use-attribute-sets="table-cell">
  <xsl:attribute name="font-weight" select="'bold'" />
  <xsl:attribute name="axf:pdftag" select="'TH'" />
</xsl:attribute-set>

<xsl:attribute-set name="title" use-attribute-sets="section-title">
  <xsl:attribute name="font-size" select="'1.5em'" />
  <xsl:attribute name="text-align" select="'center'" />
  <xsl:attribute name="space-after" select="'1em'" />
  <xsl:attribute name="keep-with-next" select="'always'" />
</xsl:attribute-set>

<!-- ============================================================= -->
<!-- TEMPLATES                                                     -->
<!-- ============================================================= -->

<xsl:template match="/">
  <xsl:apply-templates />

  <!-- Accumulator values. -->
  <xsl:variable name="page-block-average"
                select="accumulator-after('page-block-average')"
                as="array(array(item()))" />

  <fo:root xsl:use-attribute-sets="document-defaults">
    <fo:layout-master-set>
      <fo:simple-page-master
          master-name="summary"
          page-width="{$page-width}" page-height="{$page-height}"
          margin="{$page-margin}">
        <fo:region-body column-count="2"
                        column-gap="{$body-column-gap}" />
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
        <fo:region-after margin-top="0.25em" />
      </fo:simple-page-master>
      <fo:simple-page-master
          master-name="page-rest"
          page-width="{$page-width}" page-height="{$page-height}"
          margin="{$page-margin}">
        <fo:region-body
            column-count="2"
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
    <fo:declarations>
      <axf:document-info
          name="document-title"
          value="{if (exists(at:AreaRoot/@document-info.document-title))
                    then string-join(('AH Formatter Analysis Report for ‘',
                                      at:AreaRoot/@document-info.document-title,
                                      '’'),
                                     '')
                  else axf:l10n('AH Formatter Analysis Report')}" />
      <axf:document-info
          name="displaydoctitle"
          value="true" />
      <axf:document-info
          name="fitwindow"
          value="true" />
    </fo:declarations>
    <xsl:call-template name="report-summary">
      <xsl:with-param name="page-block-average"
                      select="$page-block-average"
                      as="array(array(item()))" />
    </xsl:call-template>
    <xsl:call-template name="report-pages">
      <xsl:with-param name="page-block-average"
                      select="$page-block-average"
                      as="array(array(item()))" />
    </xsl:call-template>
  </fo:root>
</xsl:template>


<xsl:template name="report-summary">
  <xsl:param name="page-block-average"
             select="accumulator-after('page-block-average')"
             as="array(array(item()))" />

  <fo:page-sequence master-reference="summary" id="summary">
    <fo:flow flow-name="xsl-region-body">
      <fo:block xsl:use-attribute-sets="title">
        <xsl:value-of select="axf:l10n('AH Formatter Analysis Report')" />
      </fo:block>
      <fo:table>
        <fo:table-body>
          <xsl:if test="exists(at:AreaRoot/@document-info.document-title)">
            <fo:table-row>
              <fo:table-cell xsl:use-attribute-sets="table-head-cell">
                <fo:block>
                  <xsl:value-of select="axf:l10n('Title')" />
                </fo:block>
              </fo:table-cell>
              <fo:table-cell xsl:use-attribute-sets="table-cell">
                <fo:block>
                  <xsl:value-of select="at:AreaRoot/@document-info.document-title" />
                </fo:block>
              </fo:table-cell>
            </fo:table-row>
          </xsl:if>
          <fo:table-row>
            <fo:table-cell xsl:use-attribute-sets="table-head-cell">
              <fo:block>
                <xsl:value-of select="axf:l10n('File')" />
              </fo:block>
            </fo:table-cell>
            <fo:table-cell xsl:use-attribute-sets="table-cell"><fo:block>
              <xsl:value-of select="$file" />
              <xsl:if test="exists($file-date)">
                <fo:block />
                <xsl:value-of select="axf:l10n('Modification date: ')" />
                <xsl:value-of select="$file-date" />
              </xsl:if>
            </fo:block>
            </fo:table-cell>
          </fo:table-row>
          <fo:table-row>
            <fo:table-cell xsl:use-attribute-sets="table-head-cell">
              <fo:block>AH Formatter</fo:block>
            </fo:table-cell>
            <fo:table-cell xsl:use-attribute-sets="table-cell">
              <fo:block>
                <xsl:value-of select="normalize-space(substring-before(comment()[1], 'Copyright'))" />
              </fo:block>
            </fo:table-cell>
          </fo:table-row>
        </fo:table-body>
      </fo:table>
      <fo:block-container orphans="1" widows="1" space-before="1em"
                          text-depth="0"
                          keep-with-previous.within-page="always">
        <xsl:if test="array:size($page-block-average) &lt;=
                      xs:integer($summary-page-keep-limit)">
          <xsl:attribute name="keep-together.within-page"
                         select="'always'" />
          <xsl:attribute name="overflow" select="'condense'" />
          <xsl:attribute name="axf:overflow-condense"
                         select="'font-size'" />
        </xsl:if>
        <fo:block>
          <xsl:for-each
              select="1 to array:size($page-block-average)">
            <xsl:variable
                name="abs-page-number"
                select="xs:string(.)"
                as="xs:string" />
            <xsl:variable
                name="has-errors"
                select="exists($errors-doc/errors/error[@page = $abs-page-number])"
                as="xs:boolean" />
            <xsl:variable
                name="thumbnail-border-color"
                select="if ($has-errors) then 'red' else 'transparent'"
                as="xs:string" />
            <xsl:variable
                name="page-block"
                select="$page-block-average(.)"
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
                    name="tooltip">
                  <xsl:value-of
                      select="axf:l10n('page-n-m',
                               (format-number(number($page-info(2)),
                                              $page-info(3)),
                                              $abs-page-number))"/>
                  <xsl:for-each
                      select="$errors-doc/errors/error[@page = $abs-page-number]
                                                      [normalize-space(@message) ne '']">
                    <!--<xsl:message select="." />-->
                    <xsl:text>&#xA;</xsl:text>
                    <xsl:value-of
                        select="if (contains(@message, ': '))
                                  then axf:l10n(concat(substring-before(@message, ': '),
                                                ': '))
                                else axf:l10n(@message)" />
                    <xsl:value-of select="substring-after(@message, ': ')" />
                  </xsl:for-each>
                </xsl:variable>
                <axf:form-field
                    field-type="button"
                    axf:field-description="{$tooltip}"
                    internal-destination="__report_page_{$abs-page-number}"
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
                <fo:inline
                    border="{$page-image-border-width} solid {$thumbnail-border-color}">
                  <fo:external-graphic
                      src="{$pdf-file}#page={.}"
                      border="0.5pt solid silver"
                      alignment-baseline="after-edge"
                      max-height="2em"
                      max-width="2em" />
                </fo:inline>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </fo:block>
      </fo:block-container>
    </fo:flow>
  </fo:page-sequence>
</xsl:template>

<xsl:template name="report-pages">
  <xsl:param name="page-block-average"
             select="accumulator-after('page-block-average')"
             as="array(array(item()))" />
  <xsl:for-each
      select="1 to array:size($page-block-average)">
    <xsl:variable
        name="abs-page-number"
        select="xs:string(.)"
        as="xs:string" />
    <xsl:variable
        name="page-block"
        select="$page-block-average(.)"
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
    <xsl:variable
        name="page-scale"
        select="min(($page-image-available-width div $this-page-width,
                     $page-image-available-height div $this-page-height,
                     1))"
          as="xs:double" />
      <xsl:if
          test="exists($errors-doc/errors/error[@page = $abs-page-number])">
    <fo:page-sequence master-reference="page-pages"
                      id="__report_page_{$abs-page-number}">
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
        <fo:block xsl:use-attribute-sets="per-page-title">
          <xsl:value-of
              select="axf:l10n('page-n-m',
                               (format-number(number($page-info(2)),
                                              $page-info(3)),
                                              $abs-page-number))"
              separator="" />
          <!--<xsl:text>Page </xsl:text>
          <xsl:number
              value="$page-info(2)"
              format="{$page-info(3)}" />
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$abs-page-number" />
          <xsl:text>)</xsl:text>-->
        </fo:block>
        <fo:list-block xsl:use-attribute-sets="list-block">
          <xsl:for-each
              select="$errors-doc/errors/error[@page = $abs-page-number]
                                              [normalize-space(@message) ne '']">
            <!--<xsl:message select="." />-->
            <fo:list-item xsl:use-attribute-sets="list-item">
              <fo:list-item-label
                  xsl:use-attribute-sets="error-label list-item-label">
                <fo:block color="{axf:color(position())}">
                  <fo:basic-link
                      internal-destination="__report_page_{$abs-page-number}_{position()}">
                    <xsl:value-of select="position()" />
                  </fo:basic-link>
                </fo:block>
              </fo:list-item-label>
              <fo:list-item-body xsl:use-attribute-sets="list-item-body">
                <fo:block>
                  <xsl:value-of
                      select="if (contains(@message, ': '))
                                then axf:l10n(concat(substring-before(@message, ': '),
                                              ': '))
                              else axf:l10n(@message)" />
                  <xsl:value-of select="substring-after(@message, ': ')" />
                </fo:block>
              </fo:list-item-body>
            </fo:list-item>
          </xsl:for-each>
        </fo:list-block>
        <!--<fo:block>
          <xsl:value-of
              select="format-number($this-page-width, '0.#'),
                      format-number($this-page-height,'0.#'),
                      $page-image-available-width,
                      $page-image-available-height,
                      format-number($page-scale, '0.####'),
                      format-number($page-image-available-width div $this-page-width, '0.####'),
                      format-number($page-image-available-height div $this-page-height, '0.####')" />
        </fo:block>-->

      </fo:flow>
      <fo:flow flow-name="page-image">
        <fo:block text-depth="0" line-height="0" font-size="0"
                  margin-top="-{$page-image-border-width}"
                  margin-left="-{$page-image-border-width}">
          <fo:external-graphic
              src="{$pdf-file}#page={.}"
              border="{$page-image-border-width} solid silver"
              max-height="100%"
              max-width="100% - {$page-image-border-width}" />
        </fo:block>
          <xsl:for-each
              select="$errors-doc/errors/error[@page = $abs-page-number]">
            <!-- Extent of error region. -->
            <fo:block-container
                position="absolute"
                left="{concat(@ax * $page-scale, 'pt')}"
                top="{concat(@ay * $page-scale, 'pt')}"
                width="{concat((@bx - @ax) * $page-scale, 'pt')}"
                height="{concat((@by - @ay) * $page-scale, 'pt')}"
                border="thin solid red"
                border-color="{axf:border-color(position())}"
                axf:border-radius="2pt"/>
            <!-- Numbered callout only if @message. -->
            <xsl:if test="normalize-space(@message) ne ''">
              <fo:block-container
                  position="absolute" width="2em"
                  left="{concat(@ax * $page-scale, 'pt')} + {axf:l10n(string-join(('report-', @code, '-left'), ''))}"
                  top="{concat(@ay * $page-scale, 'pt')}">
                <!--<fo:float axf:float="right page" clear="both">-->
                <fo:block
                    id="__report_page_{$abs-page-number}_{position()}"
                    xsl:use-attribute-sets="error-label"
                    color="{axf:color(position())}">
                  <xsl:value-of select="position()" />
                </fo:block><!--</fo:float>-->
              </fo:block-container>
            </xsl:if>
          </xsl:for-each>
      </fo:flow>
    </fo:page-sequence>
  </xsl:if>
</xsl:for-each>

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
        <xsl:value-of select="normalize-space(substring-before(., $location-marker))" />
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

<xsl:function name="axf:color" as="xs:string">
  <xsl:param name="position" as="xs:integer" />

  <xsl:sequence
      select="axf:color-attribute('color', $position)" />
</xsl:function>

<xsl:function name="axf:border-color" as="xs:string">
  <xsl:param name="position" as="xs:integer" />

  <xsl:sequence
      select="axf:color-attribute('border', $position)" />
</xsl:function>

<xsl:function name="axf:color-attribute" as="xs:string">
  <xsl:param name="name" as="xs:string" />
  <xsl:param name="position" as="xs:integer" />

  <xsl:sequence
      select="$colors[($position - 1) mod count($colors) + 1]/
                @*[local-name() = $name]" />
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

<!-- Array of arrays of page numbers for a page (which is also an
     array) plus the average white-space ratio for every block on the
     page (another array). -->
<xsl:accumulator name="page-block-average"
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

</xsl:stylesheet>

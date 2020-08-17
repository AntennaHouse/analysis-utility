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

<xsl:import href="report.xsl" />


<!-- ============================================================= -->
<!-- STYLESHEET PARAMETERS                                         -->
<!-- ============================================================= -->

<!-- Output page size. -->
<xsl:param name="page-width" select="'210mm'" as="xs:string" />
<xsl:param name="page-height" select="'297mm'" as="xs:string" />
<xsl:param name="body-column-count" select="1" as="xs:integer" />

<xsl:param name="compact.per-page-block-container.column-count"
           select="3" as="xs:integer" />
<xsl:param name="compact.per-page-block-container.column-gap"
           select="'5mm'" as="xs:string" />


<!-- ============================================================= -->
<!-- GLOBAL VARIABLES                                              -->
<!-- ============================================================= -->

<!-- Width of border around an error area. -->
<xsl:variable name="page-image-error-border-width" select="'0.5pt'" />

<!-- Width of border around an error area. -->
<xsl:variable name="page-image-error-border-radius" select="'1pt'" />


<!-- ============================================================= -->
<!-- ATTRIBUTE SETS                                                -->
<!-- ============================================================= -->

<!-- Ordered alphabetically. -->

<xsl:attribute-set name="compact.per-page-block-container">
  <xsl:attribute name="column-count"
                 select="$compact.per-page-block-container.column-count" />
  <xsl:attribute name="column-gap"
                 select="$compact.per-page-block-container.column-gap" />
  <xsl:attribute name="space-before" select="'1lh'" />
  <xsl:attribute name="keep-together.within-page" select="'10'" />
</xsl:attribute-set>

<xsl:attribute-set name="page-error-list.list-block">
  <xsl:attribute name="keep-together.within-column" select="2" />
  <xsl:attribute name="keep-with-next.within-column" select="1" />
</xsl:attribute-set>

<xsl:attribute-set name="per-page-image.block-container">
  <!--<xsl:attribute name="break-after" select="'column'" />-->
  <xsl:attribute name="keep-with-next.within-page" select="'always'" />
  <!-- Same as space between side-by-side images (including borders). -->
  <xsl:attribute name="space-before" select="'4mm'" />
</xsl:attribute-set>

<xsl:attribute-set name="per-page-title">
  <xsl:attribute name="font-size" select="'inherit'" />
  <xsl:attribute name="space-before" select="'1lh'" />
</xsl:attribute-set>


<!-- ============================================================= -->
<!-- NAMED TEMPLATES                                               -->
<!-- ============================================================= -->

<xsl:template name="root">
  <fo:root xsl:use-attribute-sets="document-defaults">
    <xsl:call-template name="layer-settings" />
    <xsl:call-template name="layout-master-set" />
    <xsl:call-template name="declarations" />
    <xsl:call-template name="compact-report-pages" />
  </fo:root>
</xsl:template>


<xsl:template name="compact-report-pages">
  <fo:page-sequence master-reference="summary" id="summary">
    <fo:static-content flow-name="xsl-region-after"
                       xsl:use-attribute-sets="footer">
      <fo:block>
        <xsl:value-of select="$file" />
        <xsl:if test="exists($file-date)">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$file-date" />
          <xsl:text>)</xsl:text>
        </xsl:if>
        <fo:leader leader-length.optimum="100%" />
        <fo:page-number />
      </fo:block>
    </fo:static-content>
    <fo:flow flow-name="xsl-region-body">
      <xsl:call-template name="title-and-summary" />
      <xsl:call-template name="page-thumbnails" />
      <xsl:call-template name="compact-page-reports" />
    </fo:flow>
  </fo:page-sequence>
</xsl:template>


<xsl:template name="compact-page-reports">
  <xsl:param name="all-pages-info"
             select="accumulator-after('all-pages-info')"
             as="array(array(item()))"
             tunnel="yes" />
  <xsl:param name="odd-pages-left"
             select="true()"
             as="xs:boolean"
             tunnel="yes" />

  <xsl:for-each
      select="(1 to array:size($all-pages-info))
                [$odd-pages-left and (. = 1 or . mod 2 = 0) or
                 not($odd-pages-left) and . mod 2 = 1]">
    <xsl:variable
        name="abs-page-number"
        select="." />
    <xsl:variable
        name="page-block"
        select="$all-pages-info(.)"
        as="array(item())" />
    <xsl:variable
        name="page-info"
        select="$page-block(1)"
        as="array(xs:string)" />
    <xsl:if
        test="exists($errors-doc/errors/error
                       [@page = $abs-page-number or
                        (not($odd-pages-left and $abs-page-number = 1) and
                         @page = $abs-page-number + 1)])">
      <xsl:variable
          name="first-page-item-count"
          select="count($errors-doc/errors/error[@page = $abs-page-number][exists(@message)])"
          as="xs:integer" />
      <fo:block-container
          xsl:use-attribute-sets="compact.per-page-block-container">
        <xsl:call-template name="per-page-image">
          <xsl:with-param
              name="page-info" select="$page-info"
              as="array(xs:string)" tunnel="yes" />
          <xsl:with-param
              name="abs-page-number" select="string($abs-page-number)"
              as="xs:string" tunnel="yes" />
          <xsl:with-param
              name="page-image-available-width"
              select="(ahf:mm(($page-width,
                               '-', $page-margin,
                               '-', $page-margin)) -
                       ahf:mm($compact.per-page-block-container.column-gap) *
                       ($compact.per-page-block-container.column-count - 1)) div
                       $compact.per-page-block-container.column-count"
              as="xs:double" tunnel="yes" />
        </xsl:call-template>
        <xsl:if test="not($odd-pages-left and $abs-page-number = 1) and
                      $abs-page-number + 1 &lt;= array:size($all-pages-info)">
          <xsl:call-template name="per-page-image">
            <xsl:with-param
                name="page-info" select="$page-info"
                as="array(xs:string)" tunnel="yes" />
            <xsl:with-param
                name="abs-page-number" select="string($abs-page-number + 1)"
                as="xs:string" tunnel="yes" />
            <xsl:with-param
                name="page-image-available-width"
                select="(ahf:mm(($page-width,
                                 '-', $page-margin,
                                 '-', $page-margin)) -
                         ahf:mm($compact.per-page-block-container.column-gap) *
                         ($compact.per-page-block-container.column-count - 1)) div
                         $compact.per-page-block-container.column-count"
                as="xs:double" tunnel="yes" />
            <xsl:with-param
                name="item-number-offset" select="$first-page-item-count"
                as="xs:integer" tunnel="yes" />
          </xsl:call-template>
        </xsl:if>
        <xsl:if
            test="exists($errors-doc/errors/error[@page = $abs-page-number])">
            <xsl:call-template name="per-page-title">
              <xsl:with-param
                  name="page-info" select="$page-info"
                  as="array(xs:string)" tunnel="yes" />
              <xsl:with-param
                  name="abs-page-number" select="string($abs-page-number)"
                  as="xs:string" tunnel="yes" />
            </xsl:call-template>
        <xsl:call-template name="page-error-list">
          <xsl:with-param
              name="page-errors"
              select="$errors-doc/errors/error[@page = $abs-page-number]
                                              [normalize-space(@message) ne '']"
              as="element(error)*"
              tunnel="yes" />
          <xsl:with-param
              name="abs-page-number" select="string($abs-page-number)"
              as="xs:string" tunnel="yes" />
        </xsl:call-template>
        </xsl:if>
        <xsl:if
            test="not($odd-pages-left and $abs-page-number = 1) and
                  exists($errors-doc/errors/error[@page = $abs-page-number + 1])">
          <xsl:call-template name="per-page-title">
            <xsl:with-param
                name="page-info"
                select="$all-pages-info($abs-page-number + 1)(1)"
                as="array(xs:string)" tunnel="yes" />
            <xsl:with-param
                name="abs-page-number"
                select="string($abs-page-number + 1)"
                as="xs:string" tunnel="yes" />
          </xsl:call-template>
          <xsl:call-template name="page-error-list">
            <xsl:with-param
                name="page-errors"
                select="$errors-doc/errors/error[@page = $abs-page-number + 1]
                                                [normalize-space(@message) ne '']"
                as="element(error)*" tunnel="yes" />
            <xsl:with-param
                name="abs-page-number"
                select="string($abs-page-number + 1)"
                as="xs:string" tunnel="yes" />
            <xsl:with-param
                name="item-number-offset" select="$first-page-item-count"
                as="xs:integer" tunnel="yes" />
          </xsl:call-template>
        </xsl:if>
      </fo:block-container>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>

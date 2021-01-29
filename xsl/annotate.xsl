<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:axf="http://www.antennahouse.com/names/XSL/Extensions"
    xmlns:exsl="http://exslt.org/common"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:at="http://www.antennahouse.com/names/XSL/AreaTree"
    xmlns="http://www.antennahouse.com/names/XSL/AreaTree"
    xmlns:ahferr="http://www.antennahouse.com/names/Error"
    exclude-result-prefixes="at exsl msxsl ahferr ahf axf"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document">

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

<xsl:import href="ahf-l10n-xslt1.xsl"/>


<!-- ============================================================= -->
<!-- KEYS                                                          -->
<!-- ============================================================= -->

<xsl:key name="error-codes" match="error" use="@code" />


<!-- ============================================================= -->
<!-- OUTPUT                                                        -->
<!-- ============================================================= -->

<xsl:output method="xml" encoding="utf-8" omit-xml-declaration="yes" />


<!-- ============================================================= -->
<!-- STYLESHEET PARAMETERS                                         -->
<!-- ============================================================= -->

<xsl:param name="lang"
           select="'en'" />

<!-- For 'ahf-l10n.xsl'. -->
<xsl:param name="default-lang" select="$lang" />

<!-- Annotation properties. -->
<xsl:param name="annotation-flags"
           select="'ReadOnly Locked'" />
<xsl:param name="annotation-font-family"
           select="'serif'" />
<xsl:param name="annotation-font-size"
	   select="'10pt'" />
<xsl:param name="annotation-font-style"
	   select="'normal'" />
<xsl:param name="annotation-font-weight"
	   select="'400'" />
<xsl:param name="annotation-text-align"
	   select="'left'" />

<!-- Annotation border properties. -->
<xsl:param name="border-color"
           select="'#FF000080'" />

<xsl:param name="border-radius"
           select="'1.5pt'" />

<xsl:param name="border-style"
           select="'solid'" />

<xsl:param name="border-width"
           select="'0.5pt'" />

<xsl:param name="report-layer">
    <xsl:call-template name="ahf:l10n">
      <xsl:with-param name="key" select="'Analysis report'" />
    </xsl:call-template>
</xsl:param>

<xsl:param name="logfile" />


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

<!-- **** UPDATE TO MATCH AH FORMATTER **** -->
<ahf:error-codes>
  <ahf:code decimal="45953" />
  <ahf:code decimal="45954" />
  <ahf:code decimal="45955" />
  <ahf:code decimal="45956" />
  <ahf:code decimal="45957" />
  <ahf:code decimal="45958" />
  <ahf:code decimal="45959" />
  <ahf:code decimal="45960" />
  <ahf:code decimal="45961" />
  <ahf:code decimal="45962" />
  <ahf:code decimal="45963" />
</ahf:error-codes>

<xsl:variable name="error-codes"
              select="document('')/*/ahf:error-codes/ahf:code" />

<!-- Get the errors in the Area Tree XML file. -->
<xsl:variable name="errors-doc">
  <!--<xsl:message><xsl:copy-of select="$logfile-doc" /></xsl:message>-->
  <xsl:apply-templates select="$logfile-doc" mode="logfile" />
</xsl:variable>

<!-- Carrier for the 'error-message-atts' attribute set. -->
<xsl:variable name="error-message-atts">
  <xsl:element name="error-message-atts"
               use-attribute-sets="error-message-atts" />
</xsl:variable>


<!-- ============================================================= -->
<!-- ATTRIBUTE SETS                                                -->
<!-- ============================================================= -->

<!-- Attributes for borders of error areas. -->
<xsl:attribute-set name="error-border-atts">
  <xsl:attribute name="border-after-color">
    <xsl:value-of select="$border-color" />
  </xsl:attribute>
  <xsl:attribute name="border-before-color">
    <xsl:value-of select="$border-color" />
  </xsl:attribute>
  <xsl:attribute name="border-end-color">
    <xsl:value-of select="$border-color" />
  </xsl:attribute>
  <xsl:attribute name="border-start-color">
    <xsl:value-of select="$border-color" />
  </xsl:attribute>
  <xsl:attribute name="border-after-width">
    <xsl:value-of select="$border-width" />
  </xsl:attribute>
  <xsl:attribute name="border-before-width">
    <xsl:value-of select="$border-width" />
  </xsl:attribute>
  <xsl:attribute name="border-end-width">
    <xsl:value-of select="$border-width" />
  </xsl:attribute>
  <xsl:attribute name="border-start-width">
    <xsl:value-of select="$border-width" />
  </xsl:attribute>
  <xsl:attribute name="border-after-style">
    <xsl:value-of select="$border-style" />
  </xsl:attribute>
  <xsl:attribute name="border-before-style">
    <xsl:value-of select="$border-style" />
  </xsl:attribute>
  <xsl:attribute name="border-end-style">
    <xsl:value-of select="$border-style" />
  </xsl:attribute>
  <xsl:attribute name="border-start-style">
    <xsl:value-of select="$border-style" />
  </xsl:attribute>
  <xsl:attribute name="border-top-left-radius">
    <xsl:value-of select="$border-radius" />
  </xsl:attribute>
  <xsl:attribute name="border-top-right-radius">
    <xsl:value-of select="$border-radius" />
  </xsl:attribute>
  <xsl:attribute name="border-bottom-left-radius">
    <xsl:value-of select="$border-radius" />
  </xsl:attribute>
  <xsl:attribute name="border-bottom-right-radius">
    <xsl:value-of select="$border-radius" />
  </xsl:attribute>
</xsl:attribute-set>

<!-- Attributes added only to areas for errors that have a message. -->
<xsl:attribute-set name="error-message-atts">
  <xsl:attribute name="annotation-color" >
    <xsl:value-of select="'none'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-flags" >
    <xsl:value-of select="$annotation-flags" />
  </xsl:attribute>
  <xsl:attribute name="annotation-font-family" >
    <xsl:value-of select="$annotation-font-family" />
  </xsl:attribute>
  <xsl:attribute name="annotation-font-size" >
    <xsl:value-of select="$annotation-font-size" />
  </xsl:attribute>
  <xsl:attribute name="annotation-font-style" >
    <xsl:value-of select="$annotation-font-style" />
  </xsl:attribute>
  <xsl:attribute name="annotation-font-weight" >
    <xsl:value-of select="$annotation-font-weight" />
  </xsl:attribute>
  <xsl:attribute name="annotation-height" >
    <xsl:value-of select="'auto'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-open" >
    <xsl:value-of select="'false'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-position-horizontal" >
    <xsl:value-of select="'0pt'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-position-vertical" >
    <xsl:value-of select="'0pt'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-text-align" >
    <xsl:value-of select="$annotation-text-align" />
  </xsl:attribute>
  <xsl:attribute name="annotation-text-color" >
    <xsl:value-of select="'#000000'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-type" >
    <xsl:value-of select="'Text'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-width" >
    <xsl:value-of select="'auto'" />
  </xsl:attribute>
  <xsl:attribute name="annotation-icon-name" >
    <xsl:value-of select="'Note'" />
  </xsl:attribute>
</xsl:attribute-set>

<!-- ============================================================= -->
<!-- TEMPLATES                                                     -->
<!-- ============================================================= -->

<!-- ============================================================= -->
<!-- DEFAULT MODE                                                  -->
<!-- ============================================================= -->

<xsl:template match="/">
  <!--
  <xsl:message>
    <xsl:value-of select="$logfile" />
  </xsl:message>
  -->
  <xsl:choose>
    <xsl:when test="function-available('msxsl:node-set')">
      <xsl:apply-templates>
        <xsl:with-param
            name="errors"
            select="msxsl:node-set($errors-doc)/*" />
        <xsl:with-param
            name="error-message-atts"
            select="msxsl:node-set($error-message-atts)/*/@*" />
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="function-available('exsl:node-set')">
      <xsl:apply-templates>
        <xsl:with-param
            name="errors"
            select="exsl:node-set($errors-doc)/*" />
        <xsl:with-param
            name="error-message-atts"
            select="exsl:node-set($error-message-atts)/*/@*" />
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message terminate="yes">
        <xsl:call-template name="ahf:l10n">
          <xsl:with-param
              name="key"
              select="'No node-set() function available'" />
        </xsl:call-template>
      </xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="at:AreaRoot">
  <!--<xsl:message><xsl:copy-of select="$logfile-doc" /></xsl:message>
  <xsl:message><xsl:copy-of select="$errors" /></xsl:message>
  <xsl:copy-of select="$errors-doc" />-->
  <!--<xsl:copy-of select="$errors" />-->
  <!--<xsl:copy-of select="msxsl:node-set($errors-doc)" />-->
  <xsl:param name="errors" />
  <xsl:param name="error-message-atts" />

  <xsl:copy>
    <xsl:apply-templates select="@*" />
    <xsl:if test="$errors/error[key('error-codes', @code)[1]][1]">
      <xsl:attribute
          name="layer-settings">
        <if test="normalize-space(@layer-settings) != ''">
          <xsl:value-of select="concat(@layer-settings, ', ')" />
        </if>
        <xsl:value-of select="concat('&quot;', $report-layer, '&quot;')" />
        <xsl:for-each select="$errors">
          <!-- Meunchian grouping to get one of each error code. -->
          <xsl:for-each select="error[count(. | key('error-codes', @code)[1]) = 1]">
            <xsl:text>, "</xsl:text>
            <xsl:call-template name="ahf:l10n">
              <xsl:with-param name="key" select="@code" />
            </xsl:call-template>
            <xsl:text>"</xsl:text>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates select="node()">
      <xsl:with-param name="errors" select="$errors" />
      <xsl:with-param name="error-message-atts"
                      select="$error-message-atts" />
    </xsl:apply-templates>
<!--
      <xsl:with-param name="x" select="0" tunnel="yes" />
      <xsl:with-param name="y" select="0" tunnel="yes" />
    </xsl:apply-templates>
-->
  </xsl:copy>
</xsl:template>

<xsl:template match="at:PageViewportArea">
  <xsl:param name="errors" />
  <xsl:param name="error-message-atts" />

  <xsl:copy>
    <xsl:apply-templates select="@* | node()" />
    <xsl:apply-templates mode="report" select=".">
      <xsl:with-param name="errors" select="$errors" />
      <xsl:with-param name="error-message-atts"
                      select="$error-message-atts" />
    </xsl:apply-templates>
  </xsl:copy>
</xsl:template>

<!-- Identity template. -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@* | node()" />
  </xsl:copy>
</xsl:template>


<!-- ============================================================= -->
<!-- 'report' MODE                                                 -->
<!-- ============================================================= -->

<xsl:template match="at:PageViewportArea" mode="report">
  <xsl:param name="errors" />
  <xsl:param name="error-message-atts" />

  <xsl:variable name="page" select="@abs-page-number" />
  <!-- <xsl:message select="$page, $errors/error[@page = $page]" /> -->
  <PageReferenceArea
      area-dev-flags="1:0" generated-by="page-sequence"
      is-first="true" is-last="true"
      width="{@width}" height="{@height}"
      display-role="block">
    <RegionViewportArea
        flow="flow" region="region-body" generated-by="page-sequence"
        is-first="true" is-last="true"
        width="{@width}" height="{@height}"
        region-name="report">
      <RegionReferenceArea
          generated-by="page-sequence"
          is-first="true" is-last="true"
          width="{@width}" height="{@height}"
          display-role="block">
        <MainReferenceArea
            generated-by="page-sequence"
            is-first="true" is-last="true"
            width="{@width}" height="{@height}">
          <ColumnReferenceArea
              generated-by="page-sequence"
              is-first="true" is-last="true"
              width="{@width}" height="{@height}">
            <NormalFlowReferenceArea
                generated-by="page-sequence"
                is-first="true" is-last="true"
                width="{@width}" height="{@height}">
              <BlockViewportArea
                  generated-by="block-container" z-index="999"
                  is-first="true" is-last="true"
                  width="{@width}" height="{@height}">
                <FlowReferenceArea layer="{$report-layer}"
                                   generated-by="block-container" z-index="999"
                                   is-first="true" is-last="true"
                                   width="{@width}" height="{@height}"
                                   display-role="block">
                  <xsl:apply-templates
                      select="$errors/error[@page = $page]">
                    <xsl:with-param name="error-message-atts"
                                    select="$error-message-atts" />
                  </xsl:apply-templates>
                </FlowReferenceArea>
              </BlockViewportArea>
            </NormalFlowReferenceArea>
          </ColumnReferenceArea>
        </MainReferenceArea>
      </RegionReferenceArea>
    </RegionViewportArea>
  </PageReferenceArea>
</xsl:template>

<xsl:template match="error[@message and @ax]"
              priority="10">
  <xsl:param name="error-message-atts" />

  <xsl:call-template name="ahf:rectangle">
    <xsl:with-param name="code" select="@code" />
    <xsl:with-param name="message" select="@message" />
    <xsl:with-param name="x" select="@ax" />
    <xsl:with-param name="y" select="@ay" />
    <xsl:with-param name="width" select="@bx - @ax" />
    <xsl:with-param name="height" select="@by - @ay" />
    <xsl:with-param name="error-message-atts"
                    select="$error-message-atts" />
  </xsl:call-template>
</xsl:template>

<xsl:template match="error[@message]" priority="5">
  <xsl:param name="error-message-atts" />

  <xsl:call-template name="ahf:rectangle">
    <xsl:with-param name="code" select="@code" />
    <xsl:with-param name="message" select="@message" />
    <xsl:with-param name="x" select="@x" />
    <xsl:with-param name="y" select="@y" />
    <xsl:with-param name="width" select="@width" />
    <xsl:with-param name="height" select="@height" />
    <xsl:with-param name="error-message-atts"
                    select="$error-message-atts" />
  </xsl:call-template>
</xsl:template>

<xsl:template match="error[@ax]">
  <xsl:param name="error-message-atts" />

  <xsl:call-template name="ahf:rectangle">
    <xsl:with-param name="code" select="@code" />
    <xsl:with-param name="x" select="@ax" />
    <xsl:with-param name="y" select="@ay" />
    <xsl:with-param name="width" select="@bx - @ax" />
    <xsl:with-param name="height" select="@by - @ay" />
    <xsl:with-param name="error-message-atts"
                    select="$error-message-atts" />
  </xsl:call-template>
</xsl:template>

<xsl:template match="error[@width]">
  <xsl:param name="error-message-atts" />

  <xsl:call-template name="ahf:rectangle">
    <xsl:with-param name="code" select="@code" />
    <xsl:with-param name="x" select="@x" />
    <xsl:with-param name="y" select="@y" />
    <xsl:with-param name="width" select="@width" />
    <xsl:with-param name="height" select="@height" />
    <xsl:with-param name="error-message-atts"
                    select="$error-message-atts" />
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
<xsl:template
    match="ahferr:error[@code =
                        document('')/*/ahf:error-codes/ahf:code/@decimal]"
    mode="logfile"
    xmlns="">

  <!--<xsl:message><xsl:value-of select="." /></xsl:message>-->
  <error code="{@code}">
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

<!-- Drop other errors and all text nodes. -->
<xsl:template match="* | text()" mode="logfile" />


<!-- ============================================================= -->
<!-- NAMED TEMPLATES                                               -->
<!-- ============================================================= -->

<xsl:template name="make-attributes">
  <xsl:param name="text" />

  <xsl:variable name="item" select="substring-before($text, ';')" />
  <xsl:variable name="rest" select="substring-after($text, ';')" />

  <xsl:attribute name="{normalize-space(substring-before($item, ':'))}">
    <xsl:value-of select="normalize-space(substring-after($item, ':'))" />
  </xsl:attribute>

  <xsl:if test="string-length(normalize-space($rest)) > 0">
    <xsl:call-template name="make-attributes">
      <xsl:with-param name="text" select="$rest" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="ahf:rectangle">
  <xsl:param name="code" />
  <xsl:param name="message" />
  <xsl:param name="x" />
  <xsl:param name="y" />
  <xsl:param name="width" />
  <xsl:param name="height" />
  <xsl:param name="error-message-atts" />

  <!--<xsl:message>
    <xsl:value-of
        select="concat('rectangle:: ', $code, ' ', $message, ' ', $x, ' ', $y, ' ', $width, ' ', $height)" />
  </xsl:message>-->

  <xsl:call-template name="ahf:do-rectangle">
    <xsl:with-param name="code" select="$code" />
    <xsl:with-param name="message" select="$message" />
    <xsl:with-param name="x" select="$x" />
    <xsl:with-param name="y" select="$y" />
    <xsl:with-param name="width" select="$width" />
    <xsl:with-param name="height" select="$height" />
    <xsl:with-param name="error-message-atts"
                    select="$error-message-atts" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="ahf:do-rectangle">
  <xsl:param name="code" />
  <xsl:param name="message" />
  <xsl:param name="x" />
  <xsl:param name="y" />
  <xsl:param name="width" />
  <xsl:param name="height" />
  <xsl:param name="error-message-atts" />

  <xsl:variable name="label">
    <xsl:call-template name="ahf:l10n">
      <xsl:with-param name="key" select="$code" />
    </xsl:call-template>
  </xsl:variable>

    <!--<xsl:value-of select="$label" />-->

  <AbsoluteViewportArea
      layer="{$label}"
      left-position="{$x}pt" top-position="{$y}pt"
      width="{$width}pt" height="{$height}pt"
      xsl:use-attribute-sets="error-border-atts"
      generated-by="block-container"
      is-first="true" is-last="true">
    <xsl:if test="normalize-space($message) != ''">
      <xsl:copy-of select="$error-message-atts" />
      <xsl:attribute name="annotation-author">
        <xsl:value-of select="$label" />
      </xsl:attribute>
      <xsl:attribute name="annotation-contents">
        <!-- Attempt to localize the message. -->
        <xsl:choose>
          <xsl:when test="contains($message, ':')">
            <xsl:call-template name="ahf:l10n">
              <xsl:with-param
                  name="key"
                  select="substring-before($message, ':')" />
            </xsl:call-template>
            <xsl:call-template name="ahf:l10n">
              <xsl:with-param name="key">
                <xsl:choose>
                  <xsl:when test="contains($message, ':: ')">:: </xsl:when>
                  <xsl:otherwise>: </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
            <xsl:variable name="rest"
                          select="substring-after($message, ': ')" />
            <xsl:choose>
              <xsl:when test="contains($rest, ': ')">
                <xsl:call-template name="translate-components">
                  <xsl:with-param
                      name="text"
                      select="substring-after($message, ': ')" />
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$rest" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="ahf:l10n">
              <xsl:with-param
                  name="key"
                  select="$message" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>
    <FlowReferenceArea
        width="{$width}pt" height="{$height}pt"
        display-role="block" generated-by="block-container"
        is-first="true" is-last="true" />
  </AbsoluteViewportArea>
</xsl:template>

<xsl:template name="translate-components">
  <xsl:param name="text" select="." />

  <xsl:if test="starts-with($text, ' ')">
    <xsl:text> </xsl:text>
  </xsl:if>

  <xsl:variable name="use-text"
                select="normalize-space($text)" />

  <xsl:call-template name="ahf:l10n">
    <xsl:with-param name="key"
                    select="substring-before($use-text, ': ')" />
  </xsl:call-template>
  <xsl:call-template name="ahf:l10n">
    <xsl:with-param name="key"
                    select="': '" />
  </xsl:call-template>
  <xsl:variable name="rest"
                select="substring-after($use-text, ': ')" />
  <xsl:choose>
    <xsl:when test="not(contains($rest, ';'))">
      <xsl:value-of select="$rest" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring-before($rest, ';')" />
      <xsl:text>;</xsl:text>
      <xsl:call-template name="translate-components">
        <xsl:with-param name="text"
                        select="substring-after($rest, ';')" />
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

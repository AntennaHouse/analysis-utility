<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="ahf xs">

<!-- Functions for working with lengths. -->

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
<!-- UTILITY FUNCTIONS                                             -->
<!-- ============================================================= -->

<xsl:variable name="ahf:units" as="element(unit)+">
  <unit name="in" per-inch="1"    per-pt="72"            per-mm="{1 div 25.4}" />
  <unit name="pt" per-inch="72"   per-pt="1"             per-mm="{72 div 25.4}" />
  <unit name="pc" per-inch="6"    per-pt="{1 div 12}"    per-mm="{12 div 25.4}"/>
  <unit name="cm" per-inch="2.54" per-pt="{2.54 div 72}" per-mm="0.1" />
  <unit name="mm" per-inch="25.4" per-pt="{25.4 div 72}" per-mm="1" />
  <unit name="px" per-inch="96"   per-pt="{96 div 72}"   per-mm="{96 div 25.4}" />
</xsl:variable>

<xsl:variable
    name="ahf:units-pattern"
    select="concat('(',
                   string-join($ahf:units/@name, '|'),
                   ')')"
    as="xs:string" />

<xsl:function name="ahf:sum-lengths" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence select="ahf:pt($lengths)" />
</xsl:function>

<xsl:function name="ahf:sum-lengths" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />
  <xsl:param name="unit" as="xs:string" />

  <xsl:choose>
    <xsl:when test="$unit = 'in'">
      <xsl:sequence select="ahf:in($lengths)" />
    </xsl:when>
    <xsl:when test="$unit = 'mm'">
      <xsl:sequence select="ahf:mm($lengths)" />
    </xsl:when>
    <xsl:when test="$unit = 'pt'">
      <xsl:sequence select="ahf:pt($lengths)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:message select="'Unknown unit:', $unit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="ahf:in" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence
      select="if (exists($lengths))
                then sum(for $i in 1 to count($lengths)
                           return if ($lengths[$i] = '-')
                                    then 0
                                  else if ($lengths[$i - 1] = '-')
                                    then ahf:length-to-in(concat('-', $lengths[$i]))
                                  else ahf:length-to-in($lengths[$i]))
                else 0" />
</xsl:function>

<xsl:function name="ahf:sum-lengths-to-in" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence select="ahf:in($lengths)" />
</xsl:function>

<xsl:function name="ahf:mm" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence
      select="if (exists($lengths))
                then sum(for $i in 1 to count($lengths)
                           return if ($lengths[$i] = '-')
                                    then 0
                                  else if ($lengths[$i - 1] = '-')
                                    then ahf:length-to-mm(concat('-', $lengths[$i]))
                                  else ahf:length-to-mm($lengths[$i]))
                else 0" />
</xsl:function>

<xsl:function name="ahf:sum-lengths-to-mm" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence select="ahf:mm($lengths)" />
</xsl:function>

<xsl:function name="ahf:pt" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence
      select="if (exists($lengths))
                then sum(for $i in 1 to count($lengths)
                           return if ($lengths[$i] = '-')
                                    then 0
                                  else if ($lengths[$i - 1] = '-')
                                    then ahf:length-to-pt(concat('-', $lengths[$i]))
                                  else ahf:length-to-pt($lengths[$i]))
                else 0" />
</xsl:function>

<xsl:function name="ahf:sum-lengths-to-pt" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence select="ahf:pt($lengths)" />
</xsl:function>


<xsl:function name="ahf:length" as="xs:double">
  <xsl:param name="lengths" as="xs:string*" />

  <xsl:sequence select="ahf:pt($lengths)" />
</xsl:function>

<xsl:function name="ahf:length-to-in" as="xs:double">
  <xsl:param name="length" as="xs:string" />

  <xsl:choose>
    <xsl:when
        test="matches($length,
                      concat('^-?\d+(\.\d*)?', $ahf:units-pattern, '$'))">
      <!--<xsl:message select="$length" />-->
      <xsl:analyze-string
          select="$length"
          regex="{concat('^(-?\d+(\.\d*)?)', $ahf:units-pattern, '$')}">
        <xsl:matching-substring>
          <xsl:sequence
              select="xs:double(regex-group(1)) div
                      xs:double($ahf:units[@name eq regex-group(3)]/@per-inch)" />
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message select="concat('Unrecognized length: ', $length)" />
      <xsl:sequence select="0" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="ahf:length-to-mm" as="xs:double">
  <xsl:param name="length" as="xs:string" />

  <xsl:choose>
    <xsl:when
        test="matches($length, concat('^-?\d+(\.\d*)?', $ahf:units-pattern, '$'))">
      <!--<xsl:message select="$length" />-->
      <xsl:analyze-string
          select="$length"
          regex="{concat('^(-?\d+(\.\d*)?)', $ahf:units-pattern, '$')}">
        <xsl:matching-substring>
          <xsl:sequence
              select="xs:double(regex-group(1)) div
                      xs:double($ahf:units[@name eq regex-group(3)]/@per-mm)" />
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message select="concat('Unrecognized length: ', $length)" />
      <xsl:sequence select="0" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="ahf:length-to-pt" as="xs:double">
  <xsl:param name="length" as="xs:string?" />

  <xsl:choose>
    <xsl:when test="empty($length)">
      <xsl:sequence select="0" />
    </xsl:when>
    <xsl:when
        test="matches($length,
                      concat('^-?\d+(\.\d*)?', $ahf:units-pattern, '$'))">
      <!--<xsl:message select="$length" />-->
      <xsl:analyze-string
          select="$length"
          regex="{concat('^(-?\d+(\.\d*)?)', $ahf:units-pattern, '$')}">
        <xsl:matching-substring>
          <xsl:sequence
              select="xs:double(regex-group(1)) div
                      xs:double($ahf:units[@name eq regex-group(3)]/@per-pt)" />
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message select="concat('Unrecognized length: ', $length)" />
      <xsl:sequence select="0" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

</xsl:stylesheet>

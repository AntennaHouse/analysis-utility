<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
    xmlns:axf="http://www.antennahouse.com/names/XSL/Extensions"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    exclude-result-prefixes="ahf axf msxsl">

<!-- Named templates for lookup of localized strings. -->

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
<!-- KEYS                                                          -->
<!-- ============================================================= -->

<!-- Use entry/@key as lookup for entry elements in property
     files. -->
<xsl:key name="entry" match="entry" use="@key" />


<!-- ============================================================= -->
<!-- STYLESHEET PARAMETERS                                         -->
<!-- ============================================================= -->
<!--
<xsl:param name="locale-language" select="''" />
<xsl:param name="locale-country" select="''" />
-->
<!-- Override for which language to use in reports. -->
<!--
<xsl:param name="report-lang" select="''" />
-->
<!-- This language's locale file is used as the fallback when the
     locale file(s) found from the user's language settings don't have
     a match for an ahf:l10n lookup. -->
<xsl:param name="default-lang" select="'en'" />

<!-- Directory containing locale files. -->
<xsl:param name="locale-dir" select="'locales'" />

<!-- Name of the locale file for the $report-lang language. -->
<!--
<xsl:param name="report-lang-properties-file"
	   select="concat($locale-dir, '/', $report-lang, '.xml')"
	   />
-->
<!-- Name of the locale file for $locale-language. -->
<!--
<xsl:param
    name="locale-language-properties-file"
    select="concat($locale-dir,
                   '/',
                   translate($locale-language,
                             'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                             'abcdefghijklmnopqrstuvwxyz'),
                   '.xml')" />
-->
<!-- Name of the locale file for the combined $locale-language and
     $locale-country. -->
<!--
<xsl:param
    name="locale-language-country-properties-file"
    select="concat($locale-dir, '/',
                   translate($locale-language,
                             'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                             'abcdefghijklmnopqrstuvwxyz'),
                   '-',
                   translate($locale-country,
                             'abcdefghijklmnopqrstuvwxyz',
                             'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                   '.xml')" />
-->
<!-- Name of the locale file for $default-lang. -->
<xsl:param name="default-lang-properties-file"
	   select="concat($locale-dir, '/', $default-lang, '.xml')" />


<!-- ============================================================= -->
<!-- STYLESHEET VARIABLES                                          -->
<!-- ============================================================= -->

<!-- Document node, if it exists, of the locale file for
     $report-lang. -->
<!--
<xsl:variable name="report-lang-properties-doc"
	      select="document($report-lang-properties-file)" />
-->
<!-- Document node, if it exists, of the locale file for
     $locale-language. -->
<!--
<xsl:variable
    name="locale-language-properties-doc"
    select="document($locale-language-properties-file)" />
-->
<!-- Document node, if it exists, of the locale file for the combined
     $locale-language and $locale-country. -->
<!--
<xsl:variable
    name="locale-language-country-properties-doc"
    select="document($locale-language-country-properties-file)" />
-->
<!-- Document node, if it exists, of the locale file for
     $default-lang. -->
<xsl:variable name="default-lang-properties-doc"
	      select="document($default-lang-properties-file)" />


<!-- ============================================================= -->
<!-- NAMED TEMPLATES                                               -->
<!-- ============================================================= -->

<!-- ahf:l10n($key as xs:string) as xs:string -->
<!-- Looks up $key in applicable locale files and returns value from
     first match found.  Preference, from highest to lowest, is
     $report-lang, combined $locale-language and $locale-country,
     $locale-country, and $default-lang.  Returns $key if no match
     found. -->
<xsl:template name="ahf:l10n">
  <xsl:param name="key" />

  <!-- Use value from a locale file only if the file exists and has an
       entry for $key. -->
<!--
  <xsl:variable name="report-lang-value">
    <xsl:for-each select="$report-lang-properties-doc">
      <xsl:value-of select="key('entry', $key)" />
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="locale-language-country-value">
    <xsl:for-each select="$locale-language-country-properties-doc">
      <xsl:value-of select="key('entry', $key)" />
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="locale-language-value">
    <xsl:for-each select="$locale-language-properties-doc">
      <xsl:value-of select="key('entry', $key)" />
    </xsl:for-each>
  </xsl:variable>
-->
  <xsl:variable name="default-lang-value">
    <xsl:for-each select="$default-lang-properties-doc">
      <xsl:value-of select="key('entry', $key)" />
    </xsl:for-each>
  </xsl:variable>

  <xsl:choose>
<!--
    <xsl:when test="$report-lang-properties-doc and
                    $report-lang-value">
      <xsl:value-of select="$report-lang-value" />
    </xsl:when>
    <xsl:when test="$locale-language-country-properties-doc and
                    $locale-language-country-value">
      <xsl:value-of select="$locale-language-country-value" />
    </xsl:when>
    <xsl:when test="$locale-language-properties-doc and
                    $locale-language-value">
      <xsl:value-of select="$locale-language-value" />
    </xsl:when>
-->
    <xsl:when test="$default-lang-properties-doc and
                    $default-lang-value != ''">
      <xsl:value-of select="$default-lang-value" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$key" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

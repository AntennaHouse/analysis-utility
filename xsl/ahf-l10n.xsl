<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="ahf xs">

<!-- Functions for lookup of localized strings. -->

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

<!-- Override for which language to use in reports.  $locale-languge
     and $locate-country (from 'ahrts-common.xsl') reflect the user's
     language settings, so this is really only useful when testing a
     different language's locale file. -->
<xsl:param name="report-lang" select="()" as="xs:string?" />

<!-- This language's locale file is used as the fallback when the
     locale file(s) found from the user's language settings don't have
     a match for an ahf:l10n() lookup. -->
<xsl:param name="default-lang" select="'en'" as="xs:string" />

<!-- Directory containing locale files. -->
<xsl:param name="locale-dir" select="'locales'" as="xs:string" />

<!-- Name of the locale file for the $report-lang language. -->
<xsl:param name="report-lang-properties-file"
	   select="concat($locale-dir, '/', $report-lang, '.xml')"
	   as="xs:string" />

<!-- Name of the locale file for $lang. -->
<xsl:param
    name="lang-properties-file"
    select="concat($locale-dir, '/', lower-case($lang), '.xml')"
    as="xs:string" />

<!-- Name of the locale file for $default-lang. -->
<xsl:param name="default-lang-properties-file"
	   select="concat($locale-dir, '/', $default-lang, '.xml')"
	   as="xs:string" />


<!-- ============================================================= -->
<!-- STYLESHEET VARIABLES                                          -->
<!-- ============================================================= -->

<!-- Document node, if it exists, of the locale file for
     $report-lang. -->
<xsl:variable name="report-lang-properties-doc"
	      select="if (doc-available($report-lang-properties-file))
                        then doc($report-lang-properties-file)
		      else ()"
	      as="document-node()?" />

<!-- Document node, if it exists, of the locale file for
     $lang. -->
<xsl:variable
    name="lang-properties-doc"
    select="if (doc-available($lang-properties-file))
              then doc($lang-properties-file)
	    else ()"
    as="document-node()?" />

<!-- Document node, if it exists, of the locale file for
     $default-lang. -->
<xsl:variable name="default-lang-properties-doc"
	      select="if (doc-available($default-lang-properties-file))
                        then doc($default-lang-properties-file)
		      else ()"
	      as="document-node()?" />


<!-- ============================================================= -->
<!-- FUNCTIONS                                                     -->
<!-- ============================================================= -->

<!-- ahf:l10n($key as xs:string) as xs:string -->
<!-- Looks up $key in applicable locale files and returns value from
     first match found.  Preference, from highest to lowest, is
     $report-lang, combined $lang and $default-lang.  Returns $key if
     no match found. -->
<xsl:function name="ahf:l10n" as="xs:string">
  <xsl:param name="key" as="xs:string" />

  <!-- Use value from a locale file only if the file exists and has an
       entry for $key. -->
  <xsl:choose>
    <xsl:when
	test="exists($report-lang-properties-doc) and
              exists(key('entry', $key, $report-lang-properties-doc))">
      <xsl:sequence
	  select="key('entry', $key, $report-lang-properties-doc)" />
    </xsl:when>
    <xsl:when
	test="exists($lang-properties-doc) and
              exists(key('entry', $key, $lang-properties-doc))">
      <xsl:sequence
	  select="key('entry', $key, $lang-properties-doc)" />
    </xsl:when>
    <xsl:when
	test="exists($default-lang-properties-doc) and
              exists(key('entry', $key, $default-lang-properties-doc))">
      <xsl:sequence
	  select="key('entry', $key, $default-lang-properties-doc)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$key" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<!-- ahf:l10n($key as xs:string, $arguments as item()*) as item()+ -->
<!-- Looks up $key in applicable locale files and returns result from
     substituting items from $arguments for '%1', '%2', etc. in value
     from first match found for $key.  '%%' returns as '%'. Useful for
     interpolating strings and FOs into l10n lookup.  Preference, from
     highest to lowest, for locale files is $report-lang, combined
     $lang and $default-lang.  Returns $key if no match found. -->
<xsl:function name="ahf:l10n" as="item()+">
  <xsl:param name="key" as="xs:string" />
  <xsl:param name="arguments" as="item()*" />

  <!-- Lookup is the same as for no-interpolation lookup. -->
  <xsl:variable name="pattern"
		select="ahf:l10n($key)"
		as="xs:string" />

  <!-- For '%%', substitute '%', and for '%1', '%2', etc., substitute
       corresponding item from $arguments -->
  <xsl:choose>
    <xsl:when test="contains($pattern, '%')">
      <xsl:analyze-string select="$pattern" regex="(%%)|%([0-9]+)">
	<xsl:matching-substring>
	  <xsl:choose>
	    <xsl:when test="regex-group(1) = '%%'">
	      <xsl:sequence select="'%'" />
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:sequence select="$arguments[xs:integer(regex-group(2))]" />
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:matching-substring>
	<xsl:non-matching-substring>
	  <xsl:value-of select="." />
	</xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$pattern" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    version="3.0"
    xmlns:ahf="http://www.antennahouse.com/names/XSLT/Functions/Document"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="ahf array map xs">

<!-- Functions used by multiple Antenna House stylesheets. -->

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
<!-- GLOBAL VARIABLES                                              -->
<!-- ============================================================= -->

<xsl:variable
    name="ratio-color-stretched"
    select="255, 0, 0"
    as="xs:integer+" />
<xsl:variable
    name="ratio-color-compressed"
    select="0, 0, 255"
    as="xs:integer+" />


<!-- ============================================================= -->
<!-- FUNCTIONS                                                     -->
<!-- ============================================================= -->

<!-- Gets the last component of $uri. -->
<xsl:function name="ahf:basename" as="xs:string">
  <xsl:param name="uri" as="xs:string" />

  <xsl:sequence select="tokenize($uri, '/|\\')[last()]" />
</xsl:function>

<!-- Gets the last component of $uri. -->
<xsl:function name="ahf:basename" as="xs:string">
  <xsl:param name="uri" as="xs:string" />
  <xsl:param name="suffix" as="xs:string" />

  <xsl:variable name="suffix-regex"
		select="replace(concat(if (starts-with($suffix, '.')) then '' else '.', $suffix, '$'), '\.', '\\.')"
		as="xs:string" />

  <xsl:sequence select="replace(tokenize($uri, '/')[last()], $suffix-regex, '')" />
</xsl:function>

<!-- ahf:report-properties($fo as element(), $properties as xs:string+) as xs:string -->
<!-- Generate a string with the named properties and their values for
     use, for example, in xsl:message. -->
<xsl:function name="ahf:report-properties" as="xs:string">
  <xsl:param name="fo" as="element()" />
  <xsl:param name="properties" as="xs:string+" />

  <xsl:sequence
      select="string-join((local-name($fo), '::',
                           for $property in $properties
                             return concat(' ',
                                           $property,
                                           ': ',
                                           $fo/@*[local-name() = $property],
                                           ';')),
                          '')" />
</xsl:function>

<!-- ahf:ratio-alpha($ratio as xs:double) as xs:double -->
<!-- Generate an alpha value on $ratio value. -->
<xsl:function name="ahf:ratio-alpha" as="xs:double">
  <xsl:param name="ratio" as="xs:double" />

  <xsl:sequence
      select="if ($ratio > 1.0)
                then min(($ratio - 1.0, 1.0))
              else if ($ratio &lt; 1.0)
                 then min(((1 div $ratio) - 1.0, 1.0))
              else 0" />
</xsl:function>

<!-- ahf:ratio-color($ratio as xs:double) as xs:string -->
<!-- Generate an 'rgba(...)' color based on $ratio value. -->
<xsl:function name="ahf:ratio-color" as="xs:string">
  <xsl:param name="ratio" as="xs:double" />

  <xsl:variable
      name="alpha"
      select="ahf:ratio-alpha($ratio)"
      as="xs:double" />

  <xsl:sequence
      select="ahf:ratio-color($ratio,
                              'lightgray',
                              'transparent',
                              $ratio-color-stretched,
                              $ratio-color-compressed)" />
</xsl:function>

<!-- ahf:ratio-color($ratio as xs:double, $zero as xs:string, $one as xs:string) as xs:string -->
<!-- Generate an 'rgba(...)' color based on $ratio value. -->
<xsl:function name="ahf:ratio-color" as="xs:string">
  <xsl:param name="ratio" as="xs:double" />
  <xsl:param name="zero" as="xs:string" />
  <xsl:param name="one" as="xs:string" />

  <xsl:variable
      name="alpha"
      select="ahf:ratio-alpha($ratio)"
      as="xs:double" />

  <xsl:sequence
      select="ahf:ratio-color($ratio,
                              $zero,
                              $one,
                              $ratio-color-stretched,
                              $ratio-color-compressed)" />
</xsl:function>

<!-- ahf:ratio-color($ratio as xs:double,
                     $zero as xs:string,
                     $one as xs:string,
                     $stretched as xs:numeric+,
                     $compressed as xs:numeric+) as xs:string -->
<!-- Generate an 'rgba(...)' color based on $ratio value. -->
<xsl:function name="ahf:ratio-color" as="xs:string">
  <xsl:param name="ratio" as="xs:double" />
  <xsl:param name="zero" as="xs:string" />
  <xsl:param name="one" as="xs:string" />
  <xsl:param name="stretched" as="xs:numeric+" />
  <xsl:param name="compressed" as="xs:numeric+" />

  <xsl:variable
      name="alpha"
      select="ahf:ratio-alpha($ratio)"
      as="xs:double" />

  <xsl:sequence
      select="if ($ratio = 0)
                then $zero
              else if ($ratio = 1.0)
                then $one
              else if ($ratio > 1)
                then ahf:color(ahf:rgba-to-rgb([ $stretched[1],
                                                 $stretched[2],
                                                 $stretched[3],
                                                 $alpha ]))
              else ahf:color(ahf:rgba-to-rgb([ $compressed[1],
                                               $compressed[2],
                                               $compressed[3],
                                               $alpha ]))" />
</xsl:function>

<!-- From https://stackoverflow.com/a/2049362/4092205

     Source => Target = (BGColor + Source) =
     Target.R = ((1 - Source.A) * BGColor.R) + (Source.A * Source.R)
     Target.G = ((1 - Source.A) * BGColor.G) + (Source.A * Source.G)
     Target.B = ((1 - Source.A) * BGColor.B) + (Source.A * Source.B)
-->
<xsl:function name="ahf:rgba-to-rgb" as="array(xs:numeric)">
  <xsl:param name="source" as="array(xs:numeric)" />

  <xsl:sequence
      select="ahf:rgba-to-rgb($source,
                              [ 255, 255, 255 ])" />
</xsl:function>

<xsl:function name="ahf:rgba-to-rgb" as="array(xs:numeric)">
  <xsl:param name="source" as="array(xs:numeric)" />
  <xsl:param name="background" as="array(xs:numeric)" />

  <xsl:sequence
      select="[ ahf:component-to-component($source(1),
                                           $source(4),
                                           $background(1)),
                ahf:component-to-component($source(2),
                                           $source(4),
                                           $background(2)),
                ahf:component-to-component($source(3),
                                           $source(4),
                                           $background(3)) ]" />
</xsl:function>


<xsl:function name="ahf:component-to-component" as="xs:integer">
  <xsl:param name="source" as="xs:integer" />
  <xsl:param name="alpha" as="xs:double" />
  <xsl:param name="background" as="xs:integer" />

  <xsl:sequence
      select="xs:integer(min((((1 - $alpha) * ($background div 255)) +
                               ($alpha * ($source div 255)),
                             1)) * 255)" />
</xsl:function>


<xsl:function name="ahf:color-to-string" as="xs:string">
  <xsl:param name="color" as="map(xs:string, xs:numeric)" />

  <xsl:variable
      name="has-alpha"
      select="map:contains($color, 'a')"
      as="xs:boolean" />

  <xsl:sequence
      select="concat('rgb',
                     if ($has-alpha) then 'a' else (),
                     '(',
                     format-number($color('r'), '0.###'),
                     ', ',
                     format-number($color('g'), '0.###'),
                     ', ',
                     format-number($color('b'), '0.###'),
                     if ($has-alpha)
                        then concat(', ',
                                    format-number($color('a'), '0.###'))
                     else (),
                     ')')" />
</xsl:function>

<xsl:function name="ahf:color" as="xs:string">
  <xsl:param name="color" as="array(xs:numeric)" />

  <xsl:variable
      name="clamped"
      select="[ xs:integer(min((max(($color(1), 0)), 255))),
                xs:integer(min((max(($color(2), 0)), 255))),
                xs:integer(min((max(($color(3), 0)), 255))),
                if (array:size($color) = 4)
                  then min((max(($color(4), 0)), 1))
                else () ]"
      as="array(xs:numeric?)" />

  <xsl:variable
      name="has-alpha"
      select="array:size($color) = 4"
      as="xs:boolean" />

  <xsl:sequence
      select="concat('rgb',
                     if ($has-alpha) then 'a' else (),
                     '(',
                     $clamped(1),
                     ', ',
                     $clamped(2),
                     ', ',
                     $clamped(3),
                     if ($has-alpha)
                        then concat(', ',
                                    format-number($clamped(4), '0.###'))
                     else (),
                     ')')" />
</xsl:function>

<xsl:function name="ahf:color" as="xs:string">
  <xsl:param name="r" as="xs:integer" />
  <xsl:param name="g" as="xs:integer" />
  <xsl:param name="b" as="xs:integer" />

  <!-- Clamp component values, even though whatever processes the
       'rgb()' function would clamp values anyway. -->
  <xsl:variable
      name="r"
      select="min((max(($r, 0)), 255))"
      as="xs:integer" />

  <xsl:variable
      name="g"
      select="min((max(($g, 0)), 255))"
      as="xs:integer" />

  <xsl:variable
      name="b"
      select="min((max(($b, 0)), 255))"
      as="xs:integer" />

  <xsl:sequence
      select="concat('rgb(',
                     $r,
                     ', ',
                     $g,
                     ', ',
                     $b,
                     ')')" />
</xsl:function>

</xsl:stylesheet>

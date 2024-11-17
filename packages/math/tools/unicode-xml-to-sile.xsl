<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  Stylesheet to convert the unicode.xml file to a SILE Lua file:
  xsltproc unicode-xml-to-sile.xsl unicode.xml > ../packages/math/unicode-symbols-generated.lua
  Where unicode.xml is:
  https://raw.githubusercontent.com/w3c/xml-entities/gh-pages/unicode.xml
-->
<xsl:output method="text" indent="no"/>

<xsl:template name="format-value">
  <xsl:param name="value" />
  <xsl:choose>
    <!-- integer -->
    <xsl:when test="floor($value) = $value"><xsl:value-of select="$value" /></xsl:when>
    <!-- boolean -->
    <xsl:when test="$value = 'true' or $value = 'false'"><xsl:value-of select="$value" /></xsl:when>
    <!-- string -->
    <xsl:otherwise>"<xsl:value-of select="$value" />"</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="format-codepoint">
  <xsl:param name="codepoint" />
  <!-- Codepoint is UXXXX, remove the U -->
  <xsl:variable name="hex" select="concat('U(0x', substring($codepoint, 2), ')')" />
  <xsl:choose>
    <xsl:when test="contains($hex, '-')">
      <!-- Special case for 2-characters operators -->
      <!-- CAVEAT: We do not expect operators with more than 2 characters -->
      <xsl:value-of select="substring-before($hex, '-')" />
      <xsl:value-of select="concat(', 0x', substring-after($hex, '-'))" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$hex" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="format-class">
  <xsl:param name="class" />
  <xsl:param name="combclass" />
  <xsl:param name="description" />
  <xsl:choose>
    <xsl:when test="$class = 'N'">ord</xsl:when><!-- Normal = mathord = atomType.ordinary -->
    <xsl:when test="$class = 'A'">ord</xsl:when><!-- Alphabetic = mathalpha = atomType.ordinary -->
    <xsl:when test="$class = 'B'">bin</xsl:when><!-- Binary = mathbin = atomType.binaryOperator -->
    <xsl:when test="$class = 'C'">close</xsl:when><!-- Closing = mathclose = atomType.closeSymbol -->
    <xsl:when test="$class = 'D'"><!-- Diacritic -->
      <xsl:choose>
        <xsl:when test="$combclass = '220'">botaccent</xsl:when>
        <xsl:when test="$combclass = '230'">accent</xsl:when>
        <xsl:otherwise>ord</xsl:otherwise><!-- assuming ordinary -->
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$class = 'F'">ord</xsl:when><!-- Fence = assiming ordinary -->
    <xsl:when test="$class = 'G'">ord</xsl:when><!-- Glyph Part = assuming ordinary -->
    <xsl:when test="$class = 'L'"><!-- Large -->
      <xsl:choose>
        <!-- SILE uses the atom for spacing currently (ignoring lspace and rspace) -->
        <!-- HACK: integral signs are NOT considered as mathop for spacing purpose -->
        <xsl:when test="contains($description,'INTEGRAL')">ord</xsl:when>
        <xsl:otherwise>op</xsl:otherwise><!-- mathop = atomType.bigOperator -->
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$class = 'O'">open</xsl:when><!-- Opening -->
    <xsl:when test="$class = 'P'">punct</xsl:when><!-- Punctuation -->
    <xsl:when test="$class = 'R'">rel</xsl:when><!-- Relation -->
    <xsl:when test="$class = 'S'">ord</xsl:when><!-- Space = assuming ordinary -->
    <xsl:when test="$class = 'U'">ord</xsl:when><!-- Unary = assuming ordinary -->
    <xsl:when test="$class = 'V'">bin</xsl:when><!-- Vary = assume binary and let the logic decide later -->
    <xsl:otherwise>ord</xsl:otherwise><!-- assuming ordinary if not specified -->
  </xsl:choose>
</xsl:template>

<xsl:template name="format-mathlatex">
  <xsl:param name="mathlatex" />
  <xsl:choose>
    <xsl:when test="$mathlatex">"<xsl:value-of select="substring($mathlatex, 2)" />"</xsl:when>
    <xsl:otherwise>nil</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="unicode">--- GENERATED FILE, DO NOT EDIT MANUALLY
--
-- Operator dictionary for unicode characters
--
-- Extracted from https://raw.githubusercontent.com/w3c/xml-entities/gh-pages/unicode.xml
-- (https://github.com/w3c/xml-entities)
--    Copyright David Carlisle 1999-2024
--    Use and distribution of this code are permitted under the terms of the
--    W3C Software Notice and License.
--    http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231.html
--    This file is a collection of information about how to map Unicode entities to LaTeX,
--    and various SGML/XML entity sets (ISO and MathML/HTML).
--    A Unicode character may be mapped to several entities.
--    Originally designed by Sebastian Rahtz in conjunction with Barbara Beeton for the STIX project
--

local atoms = require("packages/math/atoms")
local atomTypeShort = atoms.atomTypeShort

--- Transform a list of codepoints into a string
local function U (...)
  local t = { ... }
  local str = ""
  for i = 1, #t do
    str = str .. luautf8.char(t[i])
  end
  return str
end

local symbols = {}
local operatorDict = {}

--- Register a symbol
-- @tparam string str       String representation of the symbol
-- @tparam string shortatom Short atom type
-- @tparam string mathlatex TeX-like name of the symbol (from unicode-math)
-- @tparam string _         Unicode name of the symbol (informative)
-- @tparam table  ops       List of operator forms and their properties
local function addSymbol (str, shortatom, mathlatex, _, ops)
  if mathlatex then
    SU.debug("math.symbols", "Registering symbol", str, "as", mathlatex)
    symbols[mathlatex] = str
  end
  local op = {}
  op.atom = atomTypeShort[shortatom]
  if ops then
    op.forms = {}
    for _, v in pairs(ops) do
      if v.form then
        -- NOTE: At this point the mu unit is not yet defined, so keep it as a string.
        v.lspace = v.lspace and ("%smu"):format(v.lspace) or "0mu"
        v.rspace = v.rspace and ("%smu"):format(v.rspace) or "0mu"
        op.forms[v.form] = v
      else
        SU.warn("No form for operator " .. str .. " (operator dictionary is probably incomplete)")
      end
    end
  end
  operatorDict[str] = op
end

<xsl:apply-templates select="charlist/character" />

return {
  operatorDict = operatorDict,
  symbols = symbols
}
</xsl:template>

<xsl:template match="character">
  <xsl:variable name="mathclass" select="unicodedata/@mathclass" />
  <xsl:variable name="mathlatex" select="mathlatex[@set='unicode-math']/text()" />
  <xsl:variable name="combclass" select="unicodedata/@combclass" />
  <xsl:variable name="atom">
    <xsl:call-template name="format-class">
      <xsl:with-param name="class" select="$mathclass" />
      <xsl:with-param name="combclass" select="$combclass" />
      <xsl:with-param name="description" select="description" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:if test="$atom != 'ord' or $mathlatex or operator-dictionary">
    <xsl:text>
addSymbol(</xsl:text>
    <!-- Codepoints -->
    <xsl:call-template name="format-codepoint">
      <xsl:with-param name="codepoint" select="@id" />
    </xsl:call-template>
    <!-- Atom type -->
    <xsl:text>, "</xsl:text><xsl:value-of select="$atom" /><xsl:text>", </xsl:text>
    <!-- Math latex name or nil -->
    <xsl:call-template name="format-mathlatex">
      <xsl:with-param name="mathlatex" select="$mathlatex" />
    </xsl:call-template>
    <!-- Description -->
    <xsl:text>, "</xsl:text><xsl:value-of select="description" /><xsl:text>"</xsl:text>
    <!-- Operator dictionary or nil -->
    <xsl:choose>
      <xsl:when test="operator-dictionary">
        <xsl:text>, {</xsl:text>
          <xsl:apply-templates select="operator-dictionary">
            <xsl:sort select="@priority" data-type="number" order="descending" /><!-- sort by @priority -->
          </xsl:apply-templates>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise><xsl:text>, nil</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>)</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="operator-dictionary">
  { <xsl:for-each select="@*">
    <xsl:sort select="name()" />
    <xsl:value-of select="name()" /> = <xsl:call-template name="format-value">
      <xsl:with-param name="value" select="." />
    </xsl:call-template><xsl:if test="position() != last()">, </xsl:if>
  </xsl:for-each> }<xsl:if test="position() != last()">,</xsl:if>
</xsl:template>

</xsl:stylesheet>

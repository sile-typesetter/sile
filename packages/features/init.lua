local base = require("packages.base")

local package = pl.class(base)
package._name = "features"

local lpeg = require("lpeg")

local R, S, P, C = lpeg.R, lpeg.S, lpeg.P, lpeg.C
local Cf, Ct = lpeg.Cf, lpeg.Ct

local otFeatureMap = {
   Ligatures = {
      Required = "rlig",
      Common = "liga",
      Contextual = "clig",
      Rare = "dlig",
      Discretionary = "dlig",
      Historic = "hlig",
   },
   Fractions = {
      On = "frac",
      Alternate = "afrc",
   },
   StylisticSet = function (i)
      return string.format("ss%02i", tonumber(i))
   end,
   CharacterVariant = function (i)
      return string.format("cv%02i", tonumber(i))
   end,
   Letters = {
      Uppercase = "case",
      SmallCaps = "smcp",
      PetiteCaps = "pcap",
      UppercaseSmallCaps = "c2sc",
      UppercasePetiteCaps = "c2pc",
      Unicase = "unic",
   },
   Numbers = {
      Uppercase = "lnum",
      Lining = "lnum",
      LowerCase = "onum",
      OldStyle = "onum",
      Proportional = "pnum",
      monospaced = "tnum",
      SlashedZero = "zero",
      Arabic = "anum",
   },
   Contextuals = {
      Swash = "cswh",
      Alternate = "calt",
      WordInitial = "init",
      WordFinal = "fina",
      LineFinal = "fault",
      Inner = "medi",
   },
   VerticalPosition = {
      Superior = "sups",
      Inferior = "subs",
      Numerator = "numr",
      Denominator = "dnom",
      ScientificInferior = "sinf",
      Ordinal = "ordn",
   },
   Style = {
      Alternate = "salt",
      Italic = "ital",
      Ruby = "ruby",
      Swash = "swsh",
      Historic = "hist",
      TitlingCaps = "titl",
      HorizontalKana = "hkna",
      VerticalKana = "vkna",
   },
   Diacritics = {
      MarkToBase = "mark",
      MarkToMark = "mkmk",
      AboveBase = "abvm",
      BelowBase = "blwm",
   },
   Kerning = {
      Uppercase = "cpsp",
      On = "kern",
   },
   CJKShape = {
      Traditional = "trad",
      Simplified = "smpl",
      JIS1978 = "jp78",
      JIS1983 = "jp83",
      JIS1990 = "jp90",
      Expert = "expt",
      NLC = "nlck",
   },
   CharacterWidth = {
      Proportional = "pwid",
      Full = "fwid",
      Half = "hwid",
      Third = "twid",
      Quarter = "qwid",
      AlternateProportional = "palt",
      AlternateHalf = "halt",
   },
}

local function tagpos (pos, k, v)
   return k, { posneg = pos, value = v }
end

-- stylua: ignore start

-- Parser for feature strings
local featurename = C((1 - S",;:=")^1)
local value = C(SILE.parserBits.integer)
local tag = C(S"+-") * featurename * (P"=" * value)^0 * S",;:"^-1 / tagpos
local featurestring = Cf(Ct"" * tag^0, rawset)

-- Parser for fontspec strings
-- Refer to fontspec.pdf (see doc), Chapter 3, Table 4 (p. 37)
local fontspecsafe = R("AZ", "az", "09") + P":"
local ws = SILE.parserBits.ws
local fontspecsep = P"," * ws
local fontspecname = C(fontspecsafe^1)
local fontspeclist = ws * P"{" *
                     Ct(ws * fontspecname *
                        (fontspecsep * fontspecname * ws)^0) *
                     P"}" * ws

local otFeatures = pl.class(pl.Map)

-- stylua: ignore end

function otFeatures:_init ()
   self:super()
   local str = SILE.settings:get("font.features")
   local tbl = featurestring:match(str)
   if not tbl then
      SU.error("Unparsable Opentype feature string '" .. str .. "'")
   end
   for feat, flag in pairs(tbl) do
      self:set(feat, flag.posneg == "+")
   end
end

function otFeatures:__tostring ()
   local ret = {}
   for _, f in ipairs(self:items()) do
      ret[#ret + 1] = (f[2] and "+" or "-") .. f[1]
   end
   return table.concat(ret, ";")
end

function otFeatures:loadOption (name, val, invert)
   local posneg = not invert
   local key = otFeatureMap[name]
   if not key then
      SU.warn("Unknown OpenType feature " .. name)
   else
      local matches = lpeg.match(fontspeclist, val)
      for _, v in ipairs(matches or { val }) do
         v = v:gsub("^No", function ()
            posneg = false
            return ""
         end)
         local feat = type(key) == "function" and key(v) or key[v]
         if not feat then
            SU.warn("Bad OpenType value " .. v .. " for feature " .. name)
         else
            self:set(feat, posneg)
         end
      end
   end
end

-- Input like {Ligatures = Historic} or {Ligatures = "{Historic, Discretionary}"}
--
-- Most real-world use should be single value, but multiple value use is not
-- that odd.  Junicode, for example, a common font among medievalists, has many
-- Stylistic Sets and Character Variations, many of which make sense to enable
-- simultaneously.
function otFeatures:loadOptions (options, invert)
   SU.debug("features", "Features was", self)
   for k, v in pairs(options) do
      self:loadOption(k, v, invert)
   end
   SU.debug("features", "Features interpreted as", self)
end

function otFeatures:unloadOptions (options)
   self:loadOptions(options, true)
end

function package:registerCommands ()
   self:registerCommand("add-font-feature", function (options, _)
      local otfeatures = otFeatures()
      otfeatures:loadOptions(options)
      SILE.settings:set("font.features", tostring(otfeatures))
   end)

   self:registerCommand("remove-font-feature", function (options, _)
      local otfeatures = otFeatures()
      otfeatures:unloadOptions(options)
      SILE.settings:set("font.features", tostring(otfeatures))
   end)

   SILE.commands:pushWrapper(self, "font", function (options, content, original)
      local otfeatures = otFeatures()
      -- It is guaranteed that future releases of SILE will not implement non-OT \font
      -- features with capital letters.
      -- Cf. https://github.com/sile-typesetter/sile/issues/992#issuecomment-665575353
      -- So, we reserve 'em all. ⍩⃝
      for k, v in pairs(options) do
         if k:match("^[A-Z]") then
            otfeatures:loadOption(k, v)
            options[k] = nil
         end
      end
      SU.debug("features", "Font features parsed as:", otfeatures)
      options.features = (options.features and options.features .. ";" or "") .. tostring(otfeatures)
      return original(options, content)
   end)
end

package.documentation = [[
\begin{document}
SILE automatically applies ligatures defined by the fonts that you use.
These ligatures are defined by tables of \em{features} within the font file.
As well as ligatures (multiple glyphs displayed as a single glyph), the features tables also declare other glyph substitutions.

The standard \autodoc:command{\font} command provides an interface to selecting the features that you want SILE to apply to a font.
The features available will be specific to the font file; some fonts come with documentation explaining their supported features.
Discussion of OpenType features is beyond the scope of this manual.

These features can be turned on and off by passing “raw” feature names to the \autodoc:command{\font} command like so:

\begin[type=autodoc:codeblock]{raw}
\font[features="+dlig,+hlig"]{...} % turn on discretionary and historic ligatures
\end{raw}

However, this is unwieldy and requires memorizing the feature codes.

The \autodoc:package{features} package provides two commands, \autodoc:command{\add-font-feature} and \autodoc:command{\remove-font-feature}, which make it easier to access OpenType features.
The interface is patterned on the TeX package \code{fontspec}; for full documentation of the OpenType features supported, see the documentation for that package.\footnote{\href{http://texdoc.net/texmf-dist/doc/latex/fontspec/fontspec.pdf}}

Here is how you would turn on discretionary and historic ligatures with the \autodoc:package{features} package:

\begin[type=autodoc:codeblock]{raw}
\add-font-feature[Ligatures=Rare]\add-font-feature[Ligatures=Discretionary]
...
\remove-font-feature[Ligatures=Rare]\remove-font-feature[Ligatures=Discretionary]
\end{raw}
\end{document}
]]

return package

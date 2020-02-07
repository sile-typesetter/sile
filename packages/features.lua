local lpeg = require("lpeg")

local S, P, C = lpeg.S, lpeg.P, lpeg.C
local Cf, Ct = lpeg.Cf, lpeg.Ct

local opentype = { -- Mapping of opentype features to friendly names
  Ligatures = {
    Required = "rlig",
    Common = "liga",
    Contextual = "clig",
    Rare = "dlig",
    Discretionary = "dlig",
    Historic = "hlig"
  },
  Fractions = {
    On = "frac",
    Alternate = "afrc"
  },
  StylisticSet = function (i)
    return string.format("ss%02i", tonumber(i))
  end,
  Letters = {
    Uppercase = "case",
    SmallCaps = "smcp",
    PetiteCaps = "pcap",
    UppercaseSmallCaps = "c2sc",
    UppercasePetiteCaps = "c2pc",
    Unicase = "unic"
  },
  Numbers = {
    Uppercase = "lnum",
    Lining = "lnum",
    LowerCase = "onum",
    OldStyle = "onum",
    Proportional = "pnum",
    monospaced = "tnum",
    SlashedZero = "zero",
    Arabic = "anum"
  },
  Contextuals = {
    Swash = "cswh",
    Alternate = "calt",
    WordInitial = "init",
    WordFinal = "fina",
    LineFinal = "falt",
    Inner = "medi"
  },
  VerticalPosition = {
    Superior = "sups",
    Inferior = "subs",
    Numerator = "numr",
    Denominator = "dnom",
    ScientificInferior = "sinf",
    Ordinal = "ordn"
  },
  -- XXX Character variant support not implemented yet
  Style = {
    Alternate = "salt",
    Italic = "ital",
    Ruby = "ruby",
    Swash = "swsh",
    Historic = "hist",
    TitlingCaps = "titl",
    HorizontalKana = "hkna",
    VerticalKana = "vkna"
  },
  Diacritics = {
    MarkToBase = "mark",
    MarkToMark = "mkmk",
    AboveBase = "abvm",
    BelowBase = "blwm"
  },
  Kerning = {
    Uppercase = "cpsp",
    On = "kern"
  },
  CJKShape = {
    Traditional = "trad",
    Simplified = "smpl",
    JIS1978 = "jp78",
    JIS1983 = "jp83",
    JIS1990 = "jp90",
    Expert = "expt",
    NLC = "nlck"
  },
  CharacterWidth = {
    Proportional = "pwid",
    Full = "fwid",
    Half = "hwid",
    Third = "twid",
    Quarter = "qwid",
    AlternateProportional = "palt",
    AlternateHalf = "halt"
  }
}

local function tagpos (pos, k, v)
  return k, { posneg = pos, value = v }
end

-- Parser for feature strings
local featurename = C((1 - S",;:=")^1)
local value = C(SILE.parserBits.integer)
local tag = C(S"+-") * featurename * (P"=" * value)^0 * S",;:"^-1 / tagpos
local featurestring = Cf(Ct"" * tag^0, rawset)

local featurestring2table = function (str)
  return featurestring:match(str) or SU.error("Unparsable Opentype feature string '"..str.."'")
end

local table2featurestring = function (tbl)
  local t2 = {}
  for k, v in pairs(tbl) do t2[#t2+1] = v.posneg..k..(v.value and "="..v.value or "") end
  return table.concat(t2, ";")
end

SILE.registerCommand("add-font-feature", function (options, _)
  local t = featurestring2table(SILE.settings.get("font.features"))
  for k, v in pairs(options) do
    if not opentype[k] then SU.warn("Unknown Opentype feature "..k)
    else
      local posneg = "+"
      v = v:gsub("^No", function () posneg= "-"; return "" end)
      local res
      if type(opentype[k]) == "function" then res = opentype[k](v) else res = opentype[k][v] end
      if not res then SU.error("Bad OpenType value "..v.." for feature "..k) end
      if type(res) == "string" then
        t[res] = {posneg = posneg}
      else
        t[res.key] = { posneg = posneg, value = res.value}
      end
    end
  end

  SILE.settings.set("font.features", table2featurestring(t))
end)

SILE.registerCommand("remove-font-feature", function (options, _)
  local t = featurestring2table(SILE.settings.get("font.features"))

  for k, v in pairs(options) do
    if not opentype[k] then SU.warn("Unknown Opentype feature "..k)
    else
      v = v:gsub("^No", "")
      local res
      if type(opentype[k]) == "function" then res = opentype[k](v) else res = opentype[k][v] end
      if not res then SU.error("Bad OpenType value "..v.." for feature "..k) end
      if type(res) == "string" then t[res] = nil else t[res.key] = nil end
    end
  end

  SILE.settings.set("font.features", table2featurestring(t))
end)

return { documentation = [[\begin{document}
As mentioned in Chapter 3, SILE automatically applies ligatures defined by the fonts
that you use. These ligatures are defined by tables of \em{features} within
the font file. As well as ligatures (multiple glyphs displayed as a single glyph),
the features tables also declare other glyph substitutions.

The \code{features} package provides an interface to selecting the features that you
want SILE to apply to a font. The features available will be specific to the font file;
some fonts come with documentation explaining their supported features. Discussion
of OpenType features is beyond the scope of this manual.

These features can be turned on and off by passing ‘raw’ feature names to the
\code{\\font} command like so:

\begin{verbatim}
\line
\\font[features="+dlig,+hlig"]{...} \% turn on discretionary and historic ligatures
\line
\end{verbatim}

However, this is unwieldy and requires memorizing the feature codes. \code{features}
provides two commands, \code{\\add-font-feature} and \code{\\remove-font-feature},
which make it easier to access OpenType features. The interface is patterned on the
TeX package \code{fontspec}; for full documentation of the OpenType features supported,
see the documentation for that package.\footnote{\code{http://texdoc.net/texmf-dist/doc/latex/fontspec/fontspec.pdf}}

Here is how you would turn on discretionary and historic ligatures with the \code{features}
package:

\begin{verbatim}
\line
\\add-font-feature[Ligatures=Rare]\\add-font-feature[Ligatures=Discretionary]
...
\\remove-font-feature[Ligatures=Rare]\\remove-font-feature[Ligatures=Discretionary]
\line
\end{verbatim}
\end{document}]] }

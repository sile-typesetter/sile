local lpeg = require("lpeg")

local R, S, P, C = lpeg.R, lpeg.S, lpeg.P, lpeg.C
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
  CharacterVariant = function (i)
    return string.format("cv%02i", tonumber(i))
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

-- Parser for fontspec strings
-- Refer to fontspec.pdf (see doc), Chapter 3, Table 4 (p. 37)
local fontspecsafe = R("AZ", "az", "09") + P":"
local fontspecws = SILE.parserBits.whitespace^0
local fontspecsep = P"," * fontspecws
local fontspecname = C(fontspecsafe^1)
local fontspeclist = fontspecws * P"{" *
                     Ct(fontspecws * fontspecname *
                        (fontspecsep * fontspecname * fontspecws)^0) *
                     P"}" * fontspecws

local dumpTable = function (self)
    return pl.pretty.write(self, "")
end

local featurestring2table = function (str)
  local ret = featurestring:match(str)
  setmetatable(ret, { __tostring = dumpTable })
  return ret or SU.error("Unparsable Opentype feature string '"..str.."'")
end

local table2featurestring = function (tbl)
  local t2 = {}
  for k, v in pairs(tbl) do t2[#t2+1] = v.posneg..k..(v.value and "="..v.value or "") end
  return table.concat(t2, ";")
end

local _parsefontfeaturevalue = function (k, v)
    local posneg = "+"
    v = v:gsub("^No", function () posneg= "-"; return "" end)
    local res
    if type(opentype[k]) == "function" then
      res = opentype[k](v)
    else
      res = opentype[k][v]
    end
    if not res then SU.error("Bad OpenType value "..v.." for feature "..k) end
    if type(res) == "string" then
        return res, { posneg = posneg }
    else
        return res.key, { posneg = posneg, value = res.value }
    end
end

-- Input like {Ligatures = Historic} or {Ligatures = "{Historic, Discretionary}"}
--
-- Build intermediary table using an lpeg "fontspec" parser based on
-- fontspec.pdf, and:
--   * If multiple values, run each one through _parsefontfeaturevalue
--   * Else, run only one through _parsefontfeaturevalue
--
-- Output like { dlig = { posneg = "+" }, hlig = { posneg = "+" } }
--
-- Most real-world use should be single value, but multiple value use is not
-- that odd.  Junicode, for example, a common font among medievalists, has many
-- Stylistic Sets and Character Variations, many of which make sense to enable
-- simultaneously.
local parsefontfeatures = function (options)
  local otfeatures = featurestring2table(SILE.settings.get("font.features"))
  for k, v in pairs(options) do
    if not opentype[k] then SU.warn("Unknown Opentype feature "..k)
    else
      local features = {}
      setmetatable(features, { __tostring = dumpTable })
      local m = lpeg.match(fontspeclist, v)
      if m then
        for i, match in pairs(m) do
          features[i] = match
        end
      else
          features[k] = v
      end
      SU.debug("features", "Parsed features:", features)
      for _, vv in pairs(features) do
        local pk, pv = _parsefontfeaturevalue(k, vv)
        otfeatures[pk] = pv
      end
    end
  end
  SU.debug("features", "Interpreted features as:", otfeatures)
  return otfeatures
end

-- We do it this way so that we can use a SILE.temporarily in \font,
-- instead of calling these user-facing functions in it.
SILE.registerCommand("add-font-feature", function (options, _)
    local otfeatures = parsefontfeatures(options)
    local features_s = table2featurestring(otfeatures)
    SILE.settings.set("font.features", features_s)
    SU.debug("features", "Added features:", features_s)
end)

local removefontfeatures = function (options, _)
    local t_cur = featurestring2table(SILE.settings.get("font.features"))
    local t_rm = parsefontfeatures(options)
    local otfeatures = pl.tablex.deepcopy(t_cur)
    for k, v in pairs(t_rm) do
      -- \remove-font-features{Ligatures=NoHistoric} should not remove Historic
      if otfeatures[k] and otfeatures[k].posneg == v.posneg then
        otfeatures[k] = nil
      end
    end
    SILE.settings.set("font.features", table2featurestring(otfeatures))
    SU.debug("features", "Features were:", t_cur)
    SU.debug("features", "Removed features: ", t_rm)
    SU.debug("features", "Features are now:", otfeatures)
end
SILE.registerCommand("remove-font-feature", removefontfeatures)

local fontfn = SILE.Commands.font
SILE.registerCommand("font", function (options, content)
    -- It is guaranteed that future releases of SILE will not implement non-OT \font
    -- features with capital letters.
    -- Cf. https://github.com/sile-typesetter/sile/issues/992#issuecomment-665575353
    -- So, we reserve 'em all. ⍩⃝
    local features = {}
    local nfeatures = 0
    for k, v in pairs(options) do
        -- Does key begin with capital?
        if k:sub(1, 1):match('^[A-Z]$') then
            -- OK, possible feature.
            -- We allow \add-font-feature to give the warning if invalid.
            -- This is so user's font still considered.
            features[k] = v
            nfeatures = nfeatures + 1
        end
    end
    local feats = {}
    if nfeatures > 0 then
        feats = parsefontfeatures(features)
    end
    local features_s = SILE.settings.get("font.features")
    local features_temp = ''
    if string.len(features_s) > 0 then features_temp = features_s .. ';' end
    features_temp = features_temp .. table2featurestring(feats)
    SILE.settings.set("font.features", features_temp)
    SU.debug("features", "Font features temporarily set to:", features_temp)
    fontfn(options, content)
    SILE.settings.set("font.features", features_s)
end, "Set current font family, size, weight, style, variant, script, direction, language,\
      and features (overridden)")

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

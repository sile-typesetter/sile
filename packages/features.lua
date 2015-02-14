local opentype = { -- Mapping of opentype features to friendly names
  Ligatures = { 
    Required = "rlig", Common = "liga", Contextual = "clig", 
    Rare = "dlig", Discretionary = "dlig", Historic = "hlig"
  },
  Fractions = { On = "frac", Alternate = "afrc" },
  StylisticSet = function(i) return string.format("ss%02i", tonumber(i)) end,
  Letters = { 
    Uppercase = "case", SmallCaps = "smcp", PetiteCaps = "pcap",
    UppercaseSmallCaps = "c2sc", UppercasePetiteCaps = "c2pc",
    Unicase = "unic"
  },
  Numbers = {
    Uppercase = "lnum", Lining = "lnum", LowerCase = "onum", OldStyle = "onum",
    Proportional = "pnum", monospaced = "tnum", SlashedZero = "zero", Arabic = "anum"
  },
  Contextuals = {
    Swash = "cswh", Alternate = "calt", WordInitial = "init", WordFinal = "fina",
    LineFinal = "falt", Inner = "medi"
  },
  VerticalPosition = {
    Superior = "sups", Inferior = "subs", Numerator = "numr", Denominator = "dnom",
    ScientificInferior = "sinf", Ordinal = "ordn"
  },
  -- XXX character variant
  Style = {
    Alternate = "salt", Italic= "ital",
    Ruby= "ruby", Swash= "swsh", Historic= "hist", TitlingCaps= "titl", 
    HorizontalKana= "hkna", VerticalKana= "vkna"
  },
  Diacritics = {MarkToBase = "mark", MarkToMark = "mkmk", AboveBase = "abvm", BelowBase = "blwm" },
  Kerning = { Uppercase = "cpsp", On = "kern" },
  CJKShape = {
    Traditional = "trad", Simplified = "smpl", JIS1978 = "jp78", 
    JIS1983 = "jp83", JIS1990 = "jp90", Expert = "expt", NLC = "nlck",
  },
  CharacterWidth = {
    Proportional = "pwid", Full = "fwid", Half = "hwid", Third = "twid", 
    Quarter = "qwid", AlternateProportional = "palt", AlternateHalf = "halt", 
  },
}

-- Parser for feature strings
local lpeg = require("lpeg")
local featurename = lpeg.C((1-lpeg.S(",;:="))^1)
local value = lpeg.C(SILE.parserBits.number.integer)
local tag = lpeg.C(lpeg.S("+-")) * featurename * (lpeg.P("=") * value)^0 * lpeg.S(",;:")^-1 / function(pn,key,value) return key, { posneg = pn, value = value} end
local featurestring = lpeg.Cf(lpeg.Ct("") * tag^0, rawset)

local featurestring2table = function(s)
  return featurestring:match(s) or SU.error("Unparsable Opentype feature string '"..s.."'")
end

local table2featurestring = function(t)
  local t2 = {}
  for k,v in pairs(t) do t2[#t2+1] = v.posneg..k..(v.value and "="..v.value or "") end
  return table.concat(t2, ";")
end

SILE.registerCommand("add-font-feature", function(o,c)
  local t = featurestring2table(SILE.settings.get("font.features"))
  for k,v in pairs(o) do
    if not opentype[k] then SU.warn("Unknown Opentype feature "..k)
    else
      local posneg = "+"
      v = v:gsub("^No", function() posneg= "-"; return "" end)
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

SILE.registerCommand("remove-font-feature", function(o,c)
  local t = featurestring2table(SILE.settings.get("font.features"))

  for k,v in pairs(o) do
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
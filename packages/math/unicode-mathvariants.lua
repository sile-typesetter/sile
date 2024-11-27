local scriptType = {
   upright = 1,
   boldScript = 2,
   boldItalic = 3,
   -- tailed = 4,
   bold = 5,
   fraktur = 6,
   script = 7,
   initial = 8,
   monospace = 9,
   sansSerif = 10,
   doubleStruck = 11,
   -- looped = 12,
   -- stretched = 13,
   italic = 14,
   boldFraktur = 15,
   sansSerifBoldItalic = 16,
   sansSerifItalic = 17,
   boldSansSerif = 18,
}

local mathVariantAttribute = {
   normal = scriptType.upright,
   ["bold-script"] = scriptType.boldScript, -- MathML Core "bold-script" (annex C.1)
   ["bold-italic"] = scriptType.boldItalic, --MathML Core "bold-italic" (annex C.2)
   -- tailed = scriptType.tailed, -- MathML Core "tailed" (annex C.3) not supported yet
   bold = scriptType.bold, -- MathML Core "bold" (annex C.4)
   fraktur = scriptType.fraktur, --MatML Core "bold" (annex C.5)
   script = scriptType.script, -- MathML Core "script" (annex C.6)
   monospace = scriptType.monospace, -- MathML Core "monospace" (annex C.7)
   -- initial = scriptType.initial, -- MathML Core "initial" (annex C.8) not supported yet
   ["sans-serif"] = scriptType.sansSerif, -- MathML Core "sans-serif" (annex C.9)
   ["double-struck"] = scriptType.doubleStruck, -- MathML Core "double-struck" (annex C.10)
   -- looped = scriptType.looped, -- MathML Core "looped" (annex C.11) not supported yet
   -- stretched = scriptType.stretched,-- MathML Core "stretched" (annex C.12) not supported yet
   italic = scriptType.italic, --MathML Core "italic" (annex C.13)
   ["bold-fraktur"] = scriptType.boldFraktur, --MathML Core "bold-fraktur" (annex C.14)
   ["sans-serif-bold-italic"] = scriptType.sansSerifBoldItalic, --MathML Core "sans-serif-bold-italic" (annex C.15)
   ["sans-serif-italic"] = scriptType.sansSerifItalic, --MathML Core "sans-serif-italic" (annex C.16)
   ["bold-sans-serif"] = scriptType.boldSansSerif, --MathML Core "sans-serif-bold" (annex C.17)
}

local function mathVariantToScriptType (attr)
   if mathVariantAttribute[attr] then
      return mathVariantAttribute[attr]
   end
end

local mathScriptConversionTable = {
   latinUpper = {
      [scriptType.upright] = function (codepoint)
         return codepoint
      end,
      [scriptType.boldScript] = function (codepoint)
         -- MathML Core "bold-script" (annex C.1)
         return codepoint + 0x1D4D0 - 0x41
      end,
      [scriptType.boldItalic] = function (codepoint)
         -- MathML Core "bold-italic" (annex C.2)
         return codepoint + 0x1D468 - 0x41
      end,
      [scriptType.bold] = function (codepoint)
         -- MathML Core "bold" (annex C.4)
         return codepoint + 0x1D400 - 0x41
      end,
      [scriptType.doubleStruck] = function (codepoint)
         -- MathML Core "double-struck" (annex C.10)
         return codepoint == 0x43 and 0x2102 -- C
            or codepoint == 0x48 and 0x210D -- H
            or codepoint == 0x4E and 0x2115 -- N
            or codepoint == 0x50 and 0x2119 -- P
            or codepoint == 0x51 and 0x211A -- Q
            or codepoint == 0x52 and 0x211D -- R
            or codepoint == 0x5A and 0x2124 -- Z
            or codepoint + 0x1D538 - 0x41
      end,
      [scriptType.fraktur] = function (codepoint)
         -- MathML Core "fraktur" (annex C.5)
         return codepoint == 0x43 and 0x212D -- C
            or codepoint == 0x48 and 0x210C -- H
            or codepoint == 0x49 and 0x2111 -- I
            or codepoint == 0x52 and 0x211C -- R
            or codepoint == 0x5A and 0x2128 -- Z
            or codepoint + 0x1D504 - 0x41
      end,
      [scriptType.script] = function (codepoint)
         -- MathML Core "script" (annex C.6)
         return codepoint == 0x42 and 0x212C -- B
            or codepoint == 0x45 and 0x2130 -- E
            or codepoint == 0x46 and 0x2131 -- F
            or codepoint == 0x48 and 0x210B -- H
            or codepoint == 0x49 and 0x2110 -- I
            or codepoint == 0x4C and 0x2112 -- L
            or codepoint == 0x4D and 0x2133 -- M
            or codepoint == 0x52 and 0x211D -- R
            or codepoint + 0x1D49C - 0x41
      end,
      [scriptType.monospace] = function (codepoint)
         -- MathML Core "monospace" (annex C.7)
         return codepoint + 0x1D670 - 0x41
      end,
      [scriptType.sansSerif] = function (codepoint)
         -- MathML Core "sans-serif" (annex C.9)
         return codepoint + 0x1D5A0 - 0x41
      end,
      [scriptType.italic] = function (codepoint)
         -- MathML Core "italic" (annex C.13)
         return codepoint + 0x1D434 - 0x41
      end,
      [scriptType.boldFraktur] = function (codepoint)
         -- MathML Core "bold-fraktur" (annex C.14)
         return codepoint + 0x1D56C - 0x41
      end,
      [scriptType.sansSerifBoldItalic] = function (codepoint)
         -- MathML Core "sans-serif-bold-italic" (annex C.15)
         return codepoint + 0x1D63C - 0x41
      end,
      [scriptType.sansSerifItalic] = function (codepoint)
         -- MathML Core "sans-serif-italic" (annex C.16)
         return codepoint + 0x1D608 - 0x41
      end,
      [scriptType.boldSansSerif] = function (codepoint)
         -- MathML Core "sans-serif-bold" (annex C.17)
         return codepoint + 0x1D5D4 - 0x41
      end,
   },
   latinLower = {
      [scriptType.upright] = function (codepoint)
         return codepoint
      end,
      [scriptType.boldScript] = function (codepoint)
         -- MathML Core "bold-script" (annex C.1)
         return codepoint + 0x1D4EA - 0x61
      end,
      [scriptType.boldItalic] = function (codepoint)
         -- MathML Core "bold-italic" (annex C.2)
         return codepoint + 0x1D482 - 0x61
      end,
      [scriptType.bold] = function (codepoint)
         -- MathML Core "bold" (annex C.4)
         return codepoint + 0x1D41A - 0x61
      end,
      [scriptType.doubleStruck] = function (codepoint)
         -- MathML Core "double-struck" (annex C.10)
         return codepoint + 0x1D552 - 0x61
      end,
      [scriptType.fraktur] = function (codepoint)
         -- MathML Core "fraktur" (annex C.5)
         return codepoint + 0x1D51E - 0x61
      end,
      [scriptType.script] = function (codepoint)
         -- MathML Core "script" (annex C.6)
         return codepoint == 0x65 and 0x212F -- e
            or codepoint == 0x67 and 0x210A -- g
            or codepoint == 0x6F and 0x2134 -- o
            or codepoint + 0x01D4B6 - 0x61
      end,
      [scriptType.monospace] = function (codepoint)
         -- MathML Core "monospace" (annex C.7)
         return codepoint + 0x1D68A - 0x61
      end,
      [scriptType.sansSerif] = function (codepoint)
         -- MathML Core "sans-serif" (annex C.9)
         return codepoint + 0x1D5BA - 0x61
      end,
      [scriptType.italic] = function (codepoint)
         -- MathML Core "italic" (annex C.13)
         return codepoint == 0x68 and 0x210E -- h
            or codepoint + 0x1D44E - 0x61
      end,
      [scriptType.boldFraktur] = function (codepoint)
         -- MathML Core "bold-fraktur" (annex C.14)
         return codepoint + 0x1D586 - 0x61
      end,
      [scriptType.sansSerifBoldItalic] = function (codepoint)
         -- MathML Core "sans-serif-bold-italic" (annex C.15)
         return codepoint + 0x1D656 - 0x61
      end,
      [scriptType.sansSerifItalic] = function (codepoint)
         -- MathML Core "sans-serif-italic" (annex C.16)
         return codepoint + 0x1D622 - 0x61
      end,
      [scriptType.boldSansSerif] = function (codepoint)
         -- MathML Core "sans-serif-bold" (annex C.17)
         return codepoint + 0x1D5EE - 0x61
      end,
   },
   number = {
      [scriptType.upright] = function (codepoint)
         return codepoint
      end,
      [scriptType.bold] = function (codepoint)
         -- MathML Core "bold" (annex C.4)
         return codepoint + 0x1D7CE - 0x30
      end,
      [scriptType.monospace] = function (codepoint)
         -- MathML Core "monospace" (annex C.7)
         return codepoint + 0x1D7F6 - 0x30
      end,
      [scriptType.sansSerif] = function (codepoint)
         -- MathML Core "sans-serif" (annex C.9)
         return codepoint + 0x1D7E2 - 0x30
      end,
      [scriptType.doubleStruck] = function (codepoint)
         -- MathML Core "double-struck" (annex C.10)
         return codepoint + 0x1D7D8 - 0x30
      end,
      [scriptType.boldSansSerif] = function (codepoint)
         -- MathML Core "sans-serif-bold" (annex C.17)
         return codepoint + 0x1D7EC - 0x30
      end,
   },
   greekUpper = {
      [scriptType.upright] = function (codepoint)
         return codepoint
      end,
      [scriptType.boldItalic] = function (codepoint)
         -- MathML Core "bold-italic" (annex C.2)
         return codepoint == 0x3F4 and 0x1D72D -- capital theta
            or codepoint == 0x2207 and 0x1D735 -- nabla
            or codepoint + 0x1D71C - 0x391 -- other characters
      end,
      [scriptType.bold] = function (codepoint)
         -- MathML Core "italic" (annex C.4)
         -- NOT ADDRESSED: Digamma exists only in upright and bold
         -- Should we care? Not sure it's used in practice in math!
         -- Ϝ U+03DC 𝟊 U+1D7CA
         return codepoint == 0x3F4 and 0x1D6B9 -- capital theta
            or codepoint == 0x2207 and 0x1D6C1 -- nabla
            or codepoint + 0x1D6A8 - 0x391 -- other characters
      end,
      [scriptType.italic] = function (codepoint)
         -- MathML Core "italic" (annex C.13)
         return codepoint == 0x3F4 and 0x1D6F3 -- capital theta
            or codepoint == 0x2207 and 0x1D6FB -- nabla
            or codepoint + 0x1D6E2 - 0x391 -- other characters
      end,
      [scriptType.sansSerifBoldItalic] = function (codepoint)
         -- MathML Core "sans-serif-bold-italic" (annex C.15)
         return codepoint == 0x3F4 and 0x1D7A1 -- capital theta
            or codepoint == 0x2207 and 0x1D7A9 -- nabla
            or codepoint + 0x1D790 - 0x391 -- other characters
      end,
      [scriptType.boldSansSerif] = function (codepoint)
         -- MathML Core "sans-serif-italic" (annex C.17)
         return codepoint == 0x3F4 and 0x1D767 -- capital theta
            or codepoint == 0x2207 and 0x1D76F -- nabla
            or codepoint + 0x1D756 - 0x391 -- other characters
      end,
   },
   greekLower = {
      [scriptType.upright] = function (codepoint)
         return codepoint
      end,
      [scriptType.boldItalic] = function (codepoint)
         -- MathML Core "bold-italic" (annex C.2)
         return codepoint == 0x3D1 and 0x1D751 -- theta
            or codepoint == 0x3D5 and 0x1D753 -- phi
            or codepoint == 0x3D6 and 0x1D755 -- pi
            or codepoint == 0x3F0 and 0x1D752 -- kappa
            or codepoint == 0x3F1 and 0x1D754 -- rho
            or codepoint == 0x3F5 and 0x1D750 -- epsilon
            or codepoint + 0x1D736 - 0x3B1 -- other characters
      end,
      [scriptType.bold] = function (codepoint)
         -- MathML Core "italic" (annex C.4)
         -- NOT ADDRESSED: Digamma exists only in upright and bold
         -- Should we care? Not sure it's used in practice in math!
         -- ϝ U+03DD 𝟋 U+1D7CB
         return codepoint == 0x3D1 and 0x1D6DD -- theta
            or codepoint == 0x3D5 and 0x1D6DF -- phi
            or codepoint == 0x3D6 and 0x1D6E1 -- pi
            or codepoint == 0x3F0 and 0x1D6DE -- kappa
            or codepoint == 0x3F1 and 0x1D6E0 -- rho
            or codepoint == 0x3F5 and 0x1D6DC -- epsilon
            or codepoint + 0x1D6C2 - 0x3B1
      end,
      [scriptType.italic] = function (codepoint)
         -- MathML Core "italic" (annex C.13)
         return codepoint == 0x3D1 and 0x1D717 -- theta
            or codepoint == 0x3D5 and 0x1D719 -- phi
            or codepoint == 0x3D6 and 0x1D71B -- pi
            or codepoint == 0x3F0 and 0x1D718 -- kappa
            or codepoint == 0x3F1 and 0x1D71A -- rho
            or codepoint == 0x3F5 and 0x1D716 -- epsilon
            or codepoint + 0x1D6FC - 0x3B1
      end,
      [scriptType.sansSerifBoldItalic] = function (codepoint)
         -- MathML Core "sans-serif-bold-italic" (annex C.15)
         return codepoint == 0x3D1 and 0x1D7C5 -- theta
            or codepoint == 0x3D5 and 0x1D7C7 -- phi
            or codepoint == 0x3D6 and 0x1D7C9 -- pi
            or codepoint == 0x3F0 and 0x1D7C6 -- kappa
            or codepoint == 0x3F1 and 0x1D7C8 -- rho
            or codepoint == 0x3F5 and 0x1D7C4 -- epsilon
            or codepoint + 0x1D7AA - 0x3B1 -- other characters
      end,
      [scriptType.boldSansSerif] = function (codepoint)
         -- MathML Core "sans-serif-italic" (annex C.17)
         return codepoint == 0x3D1 and 0x1D78B -- theta
            or codepoint == 0x3D5 and 0x1D78D -- phi
            or codepoint == 0x3D6 and 0x1D78F -- pi
            or codepoint == 0x3F0 and 0x1D78C -- kappa
            or codepoint == 0x3F1 and 0x1D78E -- rho
            or codepoint == 0x3F5 and 0x1D78A -- epsilon
            or codepoint + 0x1D770 - 0x3B1 -- other characters
      end,
   },
}

local function convertMathVariantScript (text, script)
   local converted = ""
   for _, uchr in luautf8.codes(text) do
      local dst_char = luautf8.char(uchr)
      local converter
      if uchr >= 0x41 and uchr <= 0x5A then
         converter = mathScriptConversionTable.latinUpper[script]
      elseif uchr >= 0x61 and uchr <= 0x7A then
         converter = mathScriptConversionTable.latinLower[script]
      elseif uchr >= 0x30 and uchr <= 0x39 then
         converter = mathScriptConversionTable.number[script]
      elseif
         uchr >= 0x391
            and uchr <= 0x3A9 -- Greek capital letters
            and uchr ~= 0x3A2 -- invalid character
         or uchr == 0x3F4
         or uchr == 0x2207 -- capital theta, nabla symbols
      then
         converter = mathScriptConversionTable.greekUpper[script]
      elseif
         uchr >= 0x3B1 and uchr <= 0x3C9 -- Greek small letters
         or uchr == 0x03D1 -- theta variant
         or uchr == 0x03D5 -- phi variant
         or uchr == 0x03D6 -- pi variant
         or uchr == 0x03F0 -- kappa variant
         or uchr == 0x03F1 -- rho variant
         or uchr == 0x03F5 -- epsilon variant
      then
         converter = mathScriptConversionTable.greekLower[script]
      end
      dst_char = converter and luautf8.char(converter(uchr)) or dst_char
      converted = converted .. dst_char
   end
   return converted
end

return {
   mathVariantToScriptType = mathVariantToScriptType,
   scriptType = scriptType,
   convertMathVariantScript = convertMathVariantScript,
}

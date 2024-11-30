-- IMPORTANT:
-- Normally, if we were to take MathML seriously, we would have to use the Unicode combining characters
-- for accents, unsing reverse mapping tables.
-- So our current implementation here is not fully compliant, but the whole thing is a hornet's nest.

-- Combining character check by Unicode block
-- @tparam number codepoint A Unicode codepoint
-- @treturn boolean true if the codepoint is a combining character, false otherwise
local isCombining = function (codepoint)
   return
      -- Combining Diacritical Marks (0300–036F), since version 1.0, with modifications in subsequent versions down to 4.1
      (codepoint >= 0x0300 and codepoint <= 0x036F)
         -- Combining Diacritical Marks Extended (1AB0–1AFF), version 7.0
         or (codepoint >= 0x1AB0 and codepoint <= 0x1AFF)
         -- Combining Diacritical Marks Supplement (1DC0–1DFF), versions 4.1 to 5.2
         or (codepoint >= 0x1DC0 and codepoint <= 0x1DFF)
         -- Combining Diacritical Marks for Symbols (20D0–20FF), since version 1.0, with modifications in subsequent versions down to 5.1
         or (codepoint >= 0x20D0 and codepoint <= 0x20FF)
         -- Cyrillic Extended-A (2DE0–2DFF), version 5.1
         or (codepoint >= 0x2DE0 and codepoint <= 0x2DFF)
         -- Combining Half Marks (FE20–FE2F), versions 1.0, with modifications in subsequent versions down to 8.0
         or (codepoint >= 0xFE20 and codepoint <= 0xFE2F)
         or false
end

-- MathML Core non-normative B.3 (https://www.w3.org/TR/mathml-core/#comb-noncomb)
-- W3C Working Draft 27 November 2023, and MathML Core Editor's Draft 26 November 2024 as well:
-- The table does not seem complete, see ADDED comments below so that we can map TeX atoms
-- accent and bottaccent atoms to non-combining characters...
-- For the ADDED stuff, see report https://github.com/w3c/mathml-core/issues/137#issuecomment-2508344714
-- See also https://github.com/w3c/mathml/issues/247 on a related issue.
-- Grumpy none: All these standards put together are defective by design.
local nonCombining = {
   -- Combining Diacritical Marks (0300–036F)
   [0x0300] = 0x0060, -- combining grave accent (above) > grave accent
   [0x0301] = 0x00B4, -- combining acute accent (above) > acute accent
   [0x0302] = 0x02C6, -- combining circumflex accent (above) > modifier letter circumflex accent
   [0x0303] = 0x007E, -- combining tilde (above) > tilde
   [0x0304] = 0x00AF, -- combining macron (above) > macron
   [0x0305] = 0x203E, -- combining overline (above) > overline
   [0x0306] = 0x02D8, -- combining breve (above) > breve
   [0x0307] = 0x02D9, -- combining dot (above) > dot above
   [0x0308] = 0x00A8, -- combining diaresis (above) > diaresis
   [0x030A] = 0x02DA, -- combining ring above > ring above (ADDED)
   [0x030B] = 0x02DD, -- combining double acute accent (above) > double acute accent
   [0x030C] = 0x02C7, -- combining caron (above) > caron
   -- [0x0311] (accent in unicode-math) combining inverted breve (above) has no safe non-combining equivalent
   [0x0312] = 0x00B8, -- combining comma (above) > cedilla
   [0x0316] = 0x0060, -- combining grave accent (below) > grave accent
   [0x0317] = 0x00B4, -- combining acute accent (below) > acute accent
   [0x031F] = 0x002B, -- combingin plus sign (below) > plus sign
   [0x0320] = 0x002D, -- combining minus sign (below) > minus sign
   [0x0323] = 0x002E, -- combining dot (below) > full stop
   [0x0324] = 0x00A8, -- combining diaresis (below) > diaresis
   [0x0327] = 0x00B8, -- combining cedilla (below) > cedilla
   [0x0328] = 0x02DB, -- combining ogonek (below) > ogonek
   [0x032C] = 0x02C7, -- combining caron (below) > caron
   [0x032D] = 0x005E, -- circumflex accent below
   [0x032E] = 0x02D8, -- combining breve (below) > breve
   -- [0x032F] (botaccent is unicode-math) combining inverted breve (below) has no safe non-combining equivalent
   [0x0330] = 0x007E, -- combining tilde (below) > tilde
   [0x0331] = 0x00AF, -- combining macron (below) > macron (ADDED)
   [0x0332] = 0x203E, -- combining low line (below) > overline
   [0x0333] = 0x2017, -- combining double low line (below) > double low line (ADDED)
   [0x0338] = 0x002F, -- combining long solidus overlay (over) > solidus
   -- [0x033A] (botaccent is unicode-math) combining inverted bridge below has no safe non-combining equivalent
   -- [0x033F] (accent in unicode-math) combining double overline has no safe non-combining equivalent
   -- [0x0346] (accent in unicode-math) combining bridge above has no safe non-combining equivalent
   [0x034D] = 0x2194, -- combining left-right arrow (below) > left right arrow (ADDED)
   --Combining Diacritical Marks for Symbols (20D0–20FF)
   [0x20D0] = 0x21BC, -- combining left harpoon (above) > leftwards harpoon with barb up (ADDED)
   [0x20D1] = 0x21C0, -- combining right harpoon (above) > rightwards harpoon with barb up (ADDED)
   -- [0x20D4] (accent in unicode-math) combining anticlockwise arrow above has no safe non-combining equivalent
   -- [0x20D5] (accent in unicode-math) combining clockwise arrow above has no safe non-combining equivalent
   [0x20D6] = 0x2190, -- combining left arrow (above) > left arrow [or U+27F5 long leftwards arrow?] (ADDED)
   [0x20D7] = 0x2192, -- combining right arrow (above) > right arrow [or U+27F6 long rightwards arrow?]
   [0x20DB] = 0x22EF, -- combining triple underdot (above) > midline horizontal ellipsis (ADDED, LIKELY IMPERFECT)
   --[0x20DC] (accent in unicode-math) combining four dots above has no safe non-combining equivalent
   [0x20E1] = 0x2194, -- combining left right arrow above > left right arrow (ADDED)
   -- [0x20E7] (botaccent is unicode-math) combining annuity symbol has no safe non-combining equivalent
   [0x20E8] = 0x22EF, -- combining triple underdot (below) > midline horizontal ellipsis (ADDED, LIKELY IMPERFECT)
   -- [0x20E9] (botaccent is unicode-math) combining wide bridge above has no safe non-combining equivalent
   [0x20EC] = 0x21C1, -- combining rightwards harpoon with barb downwards > rightwards harpoon with barb downwards (ADDED)
   [0x20ED] = 0x21BD, -- combining leftwards harpoon with bard downwards > leftwards harpoon with barb downwards (ADDED)
   [0x20EE] = 0x2190, -- combining left arrow (below) > left arrow [or U+27F5 long leftwards arrow?] (ADDED)
   [0x20EF] = 0x2192, -- combining right arrow (below) > right arrow [or U+27F6 long rightwards arrow?]
}

-- Make a non-combining equivalent of a combining character
-- @tparam string char A single-character string representing a combining character
-- @treturn string A single-character string representing the non-combining equivalent
local function makeNonCombining (char)
   local codepoint = luautf8.codepoint(char, 1)
   if isCombining(codepoint) then
      local noncombining = nonCombining[codepoint]
      if noncombining then
         return luautf8.char(noncombining)
      end
      SU.warn(("No non-combining equivalent for codepoint 0x%x"):format(codepoint))
   end
   return char
end

return {
   isCombining = isCombining,
   makeNonCombining = makeNonCombining,
}

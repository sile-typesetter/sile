--- Superscript folding for CSL locales.
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Objectives: replace Unicode superscripted characters with their normal
-- counterparts.
--
-- Based on Datafile for Unicode Techical Report #30
-- http://unicode.org/reports/tr30/datafiles/SuperscriptFolding.txt
-- Copyright (c) 1991-2004 Unicode, Inc.
-- For terms of use, and documentation see http://www.unicode.org/reports/tr30/
--
-- Note that TR30 is not normative (and is currently suspended)
-- Maybe we should use other sources, see:
-- https://en.wikipedia.org/wiki/Unicode_subscripts_and_superscripts
--

local supersyms = {
   -- "characters with <super> compatibility decomposition in UnicodeData.txt"
   ["ª"] = "a",
   ["²"] = "2",
   ["³"] = "3",
   ["¹"] = "1",
   ["º"] = "o",
   ["ʰ"] = "h",
   ["ʱ"] = "ɦ",
   ["ʲ"] = "j",
   ["ʳ"] = "r",
   ["ʴ"] = "ɹ",
   ["ʵ"] = "ɻ",
   ["ʶ"] = "ʁ",
   ["ʷ"] = "w",
   ["ʸ"] = "y",
   ["ˠ"] = "ɣ",
   ["ˡ"] = "l",
   ["ˢ"] = "s",
   ["ˣ"] = "x",
   ["ˤ"] = "ʕ",
   ["ᴬ"] = "A",
   ["ᴭ"] = "Æ",
   ["ᴮ"] = "B",
   ["ᴰ"] = "D",
   ["ᴱ"] = "E",
   ["ᴲ"] = "Ǝ",
   ["ᴳ"] = "G",
   ["ᴴ"] = "H",
   ["ᴵ"] = "I",
   ["ᴶ"] = "J",
   ["ᴷ"] = "K",
   ["ᴸ"] = "L",
   ["ᴹ"] = "M",
   ["ᴺ"] = "N",
   ["ᴼ"] = "O",
   ["ᴽ"] = "Ȣ",
   ["ᴾ"] = "P",
   ["ᴿ"] = "R",
   ["ᵀ"] = "T",
   ["ᵁ"] = "U",
   ["ᵂ"] = "W",
   ["ᵃ"] = "a",
   ["ᵄ"] = "ɐ",
   ["ᵅ"] = "ɑ",
   ["ᵆ"] = "ᴂ",
   ["ᵇ"] = "b",
   ["ᵈ"] = "d",
   ["ᵉ"] = "e",
   ["ᵊ"] = "ə",
   ["ᵋ"] = "ɛ",
   ["ᵌ"] = "ɜ",
   ["ᵍ"] = "g",
   ["ᵏ"] = "k",
   ["ᵐ"] = "m",
   ["ᵑ"] = "ŋ",
   ["ᵒ"] = "o",
   ["ᵓ"] = "ɔ",
   ["ᵔ"] = "ᴖ",
   ["ᵕ"] = "ᴗ",
   ["ᵖ"] = "p",
   ["ᵗ"] = "t",
   ["ᵘ"] = "u",
   ["ᵙ"] = "ᴝ",
   ["ᵚ"] = "ɯ",
   ["ᵛ"] = "v",
   ["ᵜ"] = "ᴥ",
   ["ᵝ"] = "β",
   ["ᵞ"] = "γ",
   ["ᵟ"] = "δ",
   ["ᵠ"] = "φ",
   ["ᵡ"] = "χ",
   ["⁰"] = "0",
   ["ⁱ"] = "i",
   ["⁴"] = "4",
   ["⁵"] = "5",
   ["⁶"] = "6",
   ["⁷"] = "7",
   ["⁸"] = "8",
   ["⁹"] = "9",
   ["⁺"] = "+",
   ["⁻"] = "−",
   ["⁼"] = "=",
   ["⁽"] = "(",
   ["⁾"] = ")",
   ["ⁿ"] = "n",
   -- ['℠'] = 'SM', -- Keep symbol
   -- ['™'] = 'TM', -- Keep symbol
   -- ['㆒'] = '一', -- Keep ideographic characters (?)
   -- ['㆓'] = '二',
   -- ['㆔'] = '三',
   -- ['㆕'] = '四',
   -- ['㆖'] = '上',
   -- ['㆗'] = '中',
   -- ['㆘'] = '下',
   -- ['㆙'] = '甲',
   -- ['㆚'] = '乙',
   -- ['㆛'] = '丙',
   -- ['㆜'] = '丁',
   -- ['㆝'] = '天',
   -- ['㆞'] = '地',
   -- ['㆟'] = '人',

   -- "other characters that are superscripted forms"
   ["ˀ"] = "ʔ",
   ["ˁ"] = "ʕ",
   -- ['ۥ'] = 'و', -- Keep Arabic characters (combining?)
   -- ['ۦ'] = 'ي',
}

-- pattern for groups of superscripted characters
local vals = {}
for k in pairs(supersyms) do
   table.insert(vals, k)
end
local pat = "[" .. table.concat(vals) .. "]+"

--- Replace Unicode superscripted characters with their normal counterparts.
-- @tparam string str The string to process.
-- @treturn string The string with superscripted characters replaced.
local function superfolding (str)
   return luautf8.gsub(str, pat, function (group)
      local replaced = luautf8.gsub(group, ".", function (char)
         return supersyms[char]
      end)
      return "<bibSuperScript>" .. replaced .. "</bibSuperScript>"
   end)
end

return superfolding

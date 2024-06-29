--- Casing functions for CSL locales.
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Objectives: provide functions to handle text casing in CSL locales.
--

local icu = require("justenoughicu")
-- N.B. We don't use the textcase package here:
-- The language is a BCP47 identifier from the CSL locale.

local capitalizeFirst = function (text, lang)
   local first = luautf8.sub(text, 1, 1)
   local rest = luautf8.sub(text, 2)
   return icu.case(first, lang, "upper") .. rest
end

--- Text casing methods for CSL.
-- @table casing methods for lower, upper, capitalize-first, capitalize-all, title, sentence
local casing = {
   -- Straightforward
   ["lowercase"] = function (text, lang)
      return icu.case(text, lang, "lower")
   end,
   ["uppercase"] = function (text, lang)
      return icu.case(text, lang, "upper")
   end,
   ["capitalize-first"] = capitalizeFirst,

   -- Opinionated: even ICU does not really handle this well.
   -- It does not have good support for exceptions (small words, prepositions,
   -- articles), etc. in most languages
   -- So fallback to capitalize-first.
   ["capitalize-all"] = capitalizeFirst,
   ["title"] = capitalizeFirst,

   -- Deprecated.
   -- Let's not bother with it.
   ["sentence"] = function (text, _)
      SU.warn("Sentence case is deprecated in CSL 1.0.x (ignored)")
      return text
   end,
}

return casing

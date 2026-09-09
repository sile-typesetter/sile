--- Casing functions for CSL locales.
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Objectives: provide functions to handle text casing in CSL locales.
--

local icu = require("justenoughicu")
-- N.B. We don't use SILE's textcase package here:
-- The language is a BCP47 identifier from the CSL locale.

local capitalizeFirst = function (text, lang)
   local first = luautf8.sub(text, 1, 1)
   local rest = luautf8.sub(text, 2)
   return icu.case(first, lang, "upper") .. rest
end

local casing = {
   --- Convert text to lowercase.
   -- @function lowercase
   -- @tparam string text Text to convert
   -- @tparam string lang BCP47 language identifier
   -- @treturn string Converted text
   ["lowercase"] = function (text, lang)
      return icu.case(text, lang, "lower")
   end,
   --- Convert text to uppercase.
   -- @function uppercase
   -- @tparam string text Text to convert
   -- @tparam string lang BCP47 language identifier
   -- @treturn string Converted text
   ["uppercase"] = function (text, lang)
      return icu.case(text, lang, "upper")
   end,
   --- Capitalize the first letter of the text.
   -- @function capitalize-first
   -- @tparam string text Text to convert
   -- @tparam string lang BCP47 language identifier
   -- @treturn string Converted text
   ["capitalize-first"] = capitalizeFirst,

   --- Opinionated hack for "capitalize-all" in CSL 1.0.x
   -- Even ICU does not handle this conversion well.
   -- It does not have good support for exceptions (small words, prepositions,
   -- articles, etc.) in most languages.
   -- So we fallback to `capitalize-first`.
   -- @function capitalize-all
   -- @tparam string text Text to convert
   -- @tparam string lang BCP47 language identifier
   -- @treturn string Converted text
   ["capitalize-all"] = capitalizeFirst,
   --- Opinionated hack for "capitalize-sentence" in CSL 1.0.x
   -- Even ICU does not handle this conversion well.
   -- It does not have good support for exceptions (small words, prepositions,
   -- articles, etc.) in most languages.
   -- So we fallback to `capitalize-first`.
   -- @function capitalize-sentence
   -- @tparam string text Text to convert
   -- @tparam string lang BCP47 language identifier
   -- @treturn string Converted text
   ["title"] = capitalizeFirst,

   -- Deprecated:
   -- Let's not bother with it, nor document it.
   ["sentence"] = function (text, _)
      SU.warn("Sentence case is deprecated in CSL 1.0.x (ignored)")
      return text
   end,
}

return casing

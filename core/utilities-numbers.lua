--
-- Number formatting utilities
-- MIT License (c) 2022 SILE organization
--
local icu = require("justenoughicu")

-- Language-specific number formatters add functions to this table,
-- see e.g. languages/eo.lua
local formatNumber = {
   und = {

      -- Alpha is a special case (a numbering system, though this table is for
      -- formatting style hooks normally)
      alpha = function (num)
         local out = ""
         local a = string.byte("a")
         repeat
            num = num - 1
            out = string.char(num % 26 + a) .. out
            num = (num - num % 26) / 26
         until num < 1
         return out
      end,
   },
}

-- Decent subset from unum.h
local icuStyles = {
   default = 0, -- UNUM_PATTERN_DECIMAL
   decimal = 1, -- UNUM_DECIMAL
   string = 5, -- UNUM_SPELLOUT
   ordinal = 6, -- UNUM_ORDINAL
}

-- Numbering system for which we _know_ that ICU doesn't have a
-- default(0) format style rule (i.e. spits out latin)
-- This table is just an optimization to avoid calling ICU twice when this
-- occurs, e.g. "roman" may be quite frequent as a numbering system.
local icuStyleBypass = {
   roman = true,
}

local icuFormat = function (num, lang, options)
   -- Consistency: further below we'll concatenate those, and an empty
   -- string is likely a user mistake.
   if not lang and not options.system then
      SU.warn("Number formatting needs a language or a numbering system")
      return tonumber(num)
   end

   -- ICU format style (enum)
   options.style = not options.style and "default" or options.style
   local icustyle = options.style and icuStyles[options.style]
   if not icustyle then
      SU.warn("Number formatting style is unrecognized (using default as fallback)")
      icustyle = 0
   end

   -- ICU locale: see  https://unicode-org.github.io/icu/userguide/locale/
   -- Ex. "en", "en-US", "sr-Latn"...
   local iculocale = lang or ""
   -- ICU keyword for a numbering system specifier: @numbers=xxxx
   -- The specifiers are defined here:
   -- https://github.com/unicode-org/cldr/blob/main/common/bcp47/number.xml
   if options.system then
      options.system = options.system:lower()
      iculocale = iculocale .. "@numbers=" .. options.system
      if icuStyleBypass[options.system] then
         icustyle = 1
      end
   end

   local ok, result = pcall(icu.format_number, num, iculocale, icustyle)
   if ok and options.system and icustyle == 0 and options.system ~= "latn" and result == tostring(num) then
      -- There are valid cases where "@numbers=xxxx" with default(0) and decimal(1) styles both work.
      -- Typically, with num=1234
      --   "@numbers=arab" in default(0) --> ١٢٣٤
      --   "@numbers=arab", in decimal(1) --> ١٬٢٣٤
      -- But in many cases, ICU may fallback to latin, e.g. take "roman" (or "grek")
      --   "@numbers=roman" in default(0) --> 1234
      --   "@numbers=roman" in default(1) --> MCCXXXIV
      -- Be user friendly and attempt honoring the script.
      ok, result = pcall(icu.format_number, num, "@numbers=" .. options.system, 1)
   end
   if not ok then
      SU.warn("Number formatting failed: " .. tostring(result))
   end
   return tostring(ok and result or num)
end

setmetatable(formatNumber, {
   __call = function (self, num, options, case)
      -- Formats a number according to options, and optional case
      -- Options:
      -- - system: a numbering system string, e.g. "latn" (= "arabic"), "roman", "arab", etc.
      --   With the addition of "alpha".
      --   Casing is guessed from the system (e.g. roman, Roman, ROMAN) unless specified
      -- - style: a format style string, i.e. "default", "decimal", "ordinal", "string")
      --   E.g. in English and latin script:   1234        1,234     1,124th    one thousand...
      --   Possibly extended by additional language-specific formatting rules.
      -- Obviously, some combinations of system, style and case won't do anything worth.
      if math.abs(num) > 9223372036854775807 then
         SU.warn("Integers larger than 64 bits do not reproduce properly in all formats")
      end
      options = options or {}

      -- BEGIN COMPATIBILITY SHIM
      if type(options) ~= "table" then
         -- It used to be a string aggregating both concepts.
         SU.deprecated(
            "Previous syntax of SU.formatNumber",
            "new syntax for SU.formatNumber",
            "0.14.6",
            "0.16.0",
            [[
  Previous syntax was SU.formatNumber(num, format[, case]) with a format string
  New syntax is SU.formatNumber(num, options[, case]) with an options table,
  possibly containing:
    - system: a numbering system string, e.g. "latn" (= "arabic"), "roman", "arab", etc.
      With the addition of "alpha".
      Casing is taken into account (e.g. roman, Roman, ROMAN) unless specified
    - style: a format style string, i.e. "default", "decimal", "ordinal", "string")
      E.g. in English and latin script:   1234        1,234     1,124th    one thousand...
      Possibly extended by additional language-specific formatting rules.
  Note that the new syntax doesn't handle casing on the format style, for separation of
  concerns.
]]
         )
         if not case then
            if options:match("^%l") then
               case = "lower"
            elseif options:match("^.%l") then
               case = "title"
            else
               case = "upper"
            end
         end
         if options:lower() == "nth" then
            SU.deprecated("Format 'nth' in SU.formatNumber", "'ordinal' in SU.formatNumber", "0.14.6", "0.16.0")
            options = { style = "ordinal" }
         elseif options:lower() == "string" then
            options = { style = "string" }
         elseif options:lower() == "ordinal" and SILE.settings:get("document.language") == "tr" then
            SU.deprecated(
               "Format 'ordinal' in Turkish in SU.formatNumber",
               "'ordinal-string' in SU.formatNumber",
               "0.14.6",
               "0.16.0"
            )
            options = { style = "ordinal-string" }
         else
            options = { system = options }
         end
      end
      -- END COMPATIBILITY SHIM

      if options.system == "arabic" then
         -- "arabic" is the weirdly name, but quite friendly, used e.g. in counters and
         -- in several other places, let's keep it as a compatibility alias.
         options.system = "latn"
      end

      local system = options.system
      if not case then
         if system then
            if system:match("^%l") then
               case = "lower"
            elseif system:match("^.%l") then
               case = "title"
            else
               case = "upper"
            end
         else
            case = "lower"
         end
      end
      system = system and system:lower()

      local lang = system and system == "roman" and "la" or SILE.settings:get("document.language")
      local style = options.style
      local result
      if self[lang] and style and type(self[lang][style]) == "function" then
         -- Language specific hooks exists, use them...
         result = self[lang][style](num, options)
      elseif style and type(self["und"][style]) == "function" then
         -- Global specific hooks exists: use them...
         result = self.und[system](num, options)
      elseif system and type(self["und"][system]) == "function" then
         -- TRICK: Notably, special case for "alpha"
         result = system and self.und[system](num, options)
      else
         --- Otherwise, rely on ICU...
         result = icuFormat(num, lang, options)
      end
      return icu.case(result, lang, case)
   end,
})

return formatNumber

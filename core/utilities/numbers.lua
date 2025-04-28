--- Number formatting utilities.
--- @module SU.numbers

--- @type formatNumber
-- Language-specific number formatters add functions to this table,
-- see e.g. languages/eo.lua
local formatNumber = {}

local _deprecate = function ()
   SU.deprecated(
      "SU.formatNumber",
      "language:formatNumber",
      "0.16.0",
      "0.17.0",
      [[
         The SU.formanNumber function and it's associated language specific variants have
         been moved to the language support modules. Some default styles are provided in
         the unicode base module, and language specific features are in their own
         modules. Access to this function should be achieved by getting the current
         language instance from the typesetter at `typesetter.language`, then calling it
         with the desired formatting function, e.g. `language:formatNumber()`.
      ]]
   )
end

setmetatable(formatNumber, {
   __newindex = function (lang, formatters)
      _deprecate()
      local language = SILE.typesetter:_cacheLanguage(lang)
      local numberingMethod = require("languages.unicod")._numberingMethod
      for system, func in pairs(formatters) do
         local method = numberingMethod(system)
         language[method] = func
      end
   end,
   __call = function (_, num, options, case)
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

                 - system: a numbering system string

                   e.g. "latn" (= "arabic"), "roman", "arab", etc. with the addition of
                   "alpha" and "greek". Casing is taken into account (e.g. roman, Roman,
                   ROMAN) unless specified.

                 - style: a format style string

                   i.e. "default", "decimal", "ordinal", "string"). E.g. in English and latin
                   script: 1234    1,234    1,124th    one thousand    ...
                   Possibly extended by additional language-specific formatting rules.

               Note that the new syntax doesn't handle casing on the format style, for
               separation of concerns.
            ]]
         )
      end
      _deprecate()
      return SILE.typesetter.language:formatNumber(num, options, case)
   end,
})

return formatNumber

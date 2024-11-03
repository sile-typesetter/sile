local hyphens = require("languages.no.hyphens-tex")
local patterns, exceptions = hyphens.patterns, hyphens.exceptions
return {
   init = function ()
      SILE.hyphenator.languages.no = {
         patterns = patterns,
         exceptions = exceptions,
      }
   end,
   -- Private API For inheritance to nb_NO and rn_NO
   _no = function ()
      return patterns, exceptions
   end,
}

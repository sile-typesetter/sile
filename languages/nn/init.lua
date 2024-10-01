local no = require("languages.no")._no

local no_patterns, no_exceptions = no()

local nn_patterens = pl.tablex.copy(no_patterns)

local nn_exceptions = pl.tablex.copy(no_exceptions)

-- typos: ignore start
pl.tablex.insertvalues(nn_exceptions, {
   "att-en-de",
   "bet-re",
})
-- typos: ignore end

return {
   init = function ()
      SILE.hyphenator.languages.nn = {
         patterns = nn_patterens,
         exceptions = nn_exceptions,
      }
   end,
}

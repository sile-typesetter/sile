local no = require("languages.no")._no

local no_patterns, no_exceptions = no()

local nn_patterens = pl.tablex.copy(no_patterns)

local nn_exceptions = pl.tablex.copy(no_exceptions)

pl.tablex.insertvalues(nn_exceptions, {
    "att-en-de",
    "bet-re",
  })

return {
  init = function ()
    SILE.hyphenator.languages.nn = {
      patterns = nn_patterens,
      exceptions = nn_exceptions
    }
  end
}

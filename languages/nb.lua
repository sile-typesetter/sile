local no = require("languages.no")._no

local no_patterns, no_exceptions = no()

return {
  init = function ()
    SILE.hyphenator.languages.nb = {
      patterns = no_patterns,
      exceptions = no_exceptions
    }
  end
}

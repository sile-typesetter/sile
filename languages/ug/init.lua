local tr = require("languages.tr")

local language = pl.class(tr)
language._name = "ug"

function language:declareSettings ()
   SILE.settings:declare({
      parameter = "languages.ug.hyphenoffset",
      help = "Space added between text and hyphen",
      type = "glue or nil",
      default = SILE.types.node.glue("1pt"),
   })
end

function language:setupHyphenator ()
   self.hyphenator = require("languages.ug.hyphenator")(self)
end

return language

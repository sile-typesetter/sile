local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "am"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.am.nodemaker")
end

function language:declareSettings ()
   SILE.settings:declare({
      parameter = "languages.am.justification",
      type = "string",
      default = "left",
      help = "Justification method for Ethiopic word separators: left or centered",
   })
end

return language

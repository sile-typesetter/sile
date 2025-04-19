local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "sk"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.repeat-hyphen-nodemaker")
end

return language

local base = require("languages.base")

local language = pl.class(base)
language._name = "unicode"

function language:setupNodeMaker ()
   self.nodeMaker = require("languages.unicode-nodemaker")
end

return language

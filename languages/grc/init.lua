local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "grc"

function language:setupNodeMaker ()
   self.nodeMaker = require("languages.grc.nodemaker")
end

return language

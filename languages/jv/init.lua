local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "jv"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.jv.nodemaker")
end

return language

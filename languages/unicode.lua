local base = require("languages.base")

local language = pl.class(base)
language._name = "unicode"

local nodeMaker = require("languages.unicode-nodemaker")

function language:_init ()
   base._init(self)
   self.nodeMaker = nodeMaker
end

return language

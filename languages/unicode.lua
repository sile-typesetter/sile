local base = require("languages.base")

local language = pl.class(base)
language._name = "unicode"

function language:_init (typesetter)
   base._init(self, typesetter)
end

function language:setupNodeMaker ()
   self.nodemaker = require("languages.unicode-nodemaker")
end

return language

local unicode = require("languages.unicode-nodemaker")

local nodemaker = pl.class(unicode)
nodemaker._name = "tr"

-- TODO find a more ergonomic place to put obvious properties
-- (also in French, Catalan)
function nodemaker:_init (language, options)
   unicode._init(self, language, options)
   -- Quotes may be part of a word in Turkish
   self.wordTypes = { cm = true, qu = true }
end

return nodemaker

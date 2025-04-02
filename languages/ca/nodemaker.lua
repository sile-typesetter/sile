local unicode = require("languages.unicode-nodemaker")

local nodemaker = pl.class(unicode)
nodemaker._name = "ca"

-- TODO find a more ergonomic place to put obvious properties
-- (also in French)
function nodemaker:_init (language, options)
   unicode._init(self, language, options)
   self.quoteTypes = { qu = true } -- split tokens at apostrophes etc.
end

return nodemaker

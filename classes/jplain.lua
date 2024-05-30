-- Basic! Transitional! In development! Not very good! Don't use it!
local tplain = require("classes.tplain")

local class = pl.class(tplain)
class._name = "jplain"

function class:_init (options)
   tplain._init(self, options)
   SILE.languageSupport.loadLanguage("ja")
   SILE.settings:set("document.language", "ja", true)
   SILE.settings:set("font.family", "Noto Sans CJK JP", true)
end

return class

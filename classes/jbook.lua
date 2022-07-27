local tbook = require("classes.tbook")

local class = pl.class(tbook)
class._name = "jbook"

function class:_init (options)
  tbook._init(self, options)
  SILE.languageSupport.loadLanguage("ja")
  SILE.settings:set("document.language", "ja", true)
  SILE.settings:set("font.family", "Noto Sans CJK JP", true)
  return self
end

class.declareOptions = tbook.declareOptions

class.setOptions = tbook.setOptions

return class

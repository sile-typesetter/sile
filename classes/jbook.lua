local tbook = require("classes.tbook")

local jbook = pl.class(tbook)
jbook._name = "jbook"

function jbook:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(jbook) end
  tbook._init(self, options)
  SILE.languageSupport.loadLanguage("ja")
  SILE.settings:set("document.language", "ja", true)
  SILE.settings:set("font.family", "Noto Sans CJK JP", true)
  return self
end

jbook.declareOptions = tbook.declareOptions

jbook.setOptions = tbook.setOptions

return jbook

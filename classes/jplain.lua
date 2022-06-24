-- Basic! Transitional! In development! Not very good! Don't use it!
local tplain = require("classes.tplain")

local jplain = pl.class(tplain)
jplain._name = "jplain"

function jplain:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(jplain) end
  tplain._init(self, options)
  SILE.languageSupport.loadLanguage("ja")
  SILE.settings:set("document.language", "ja", true)
  SILE.settings:set("font.family", "Noto Sans CJK JP", true)
  return self
end

return jplain

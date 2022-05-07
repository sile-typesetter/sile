-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = SILE.require("classes.plain")

local jplain = pl.class(plain)
jplain._name = "jplain"

jplain:declareOption("layout", function (self_, value)
    local omt = getmetatable(self_.options)
    if value then omt.layout = value end
    return omt.layout
  end)

jplain.defaultFrameset.content = {
  left = "8.3%pw",
  top = "11.6%ph",
  gridsize = 10,
  linegap = 7,
  linelength = 50,
  linecount = 30
}

function jplain:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(plain) end
  if not options then options = {} end
  options.layout = options.layout or "yoko"
  plain._init(self, options)
  SILE.call("bidi-off")
  self:loadPackage("font-fallback")
  SILE.call("font:add-fallback", { family = "Noto Sans CJK JP" })
  SILE.languageSupport.loadLanguage("ja")
  self:loadPackage("hanmenkyoshi")
  self.defaultFrameset.content.tate = self.options.layout() == "tate"
  self.defaultFrameset.content = self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings.set("document.parindent", SILE.nodefactory.glue("10pt"))
  return self
end

return jplain

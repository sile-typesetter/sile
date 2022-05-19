-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = require("classes.plain")

local jplain = pl.class(plain)
jplain._name = "jplain"

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
  self:declareOption("layout", function (_, value)
    if value then
      self.layout = value
      if value == "tate" then self:loadPackage("tate") end
    end
    return self.layout
  end)
  plain._init(self, options)
  self:registerPostinit(function (class)
    class:bidiDisableTypesetter(SILE.defaultTypesetter)
  end)
  self:loadPackage("font-fallback")
  SILE.call("font:add-fallback", { family = "Noto Sans CJK JP" })
  SILE.languageSupport.loadLanguage("ja")
  self:loadPackage("hanmenkyoshi")
  self.defaultFrameset.content.tate = self.options.layout == "tate"
  self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
  -- Avoid calling this (yet) if we're the parent of some child class
  if self._name == "jplain" then self:post_init() end
  return self
end

return jplain

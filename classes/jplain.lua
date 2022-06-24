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

function jplain:_j_common ()
  self:loadPackage("font-fallback")
  self:loadPackage("hanmenkyoshi")
  self:registerPostinit(function (class)
      class:bidiDisableTypesetter(SILE.typesetter)
      class:bidiDisableTypesetter(SILE.defaultTypesetter)
      SILE.call("font:add-fallback", { family = "Noto Sans CJK JP" })
    end)
  self.defaultFrameset.content.tate = self.options.layout == "tate"
  self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
end

function jplain:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(jplain) end
  plain._init(self, options)
  self:_j_common()
  return self
end

function jplain:declareOptions ()
  plain.declareOptions(self)
  self:declareOption("layout", function (_, value)
    if value then
      self.layout = value
      if value == "tate" then self:loadPackage("tate") end
    end
    return self.layout
  end)
end

function jplain:setOptions (options)
  options.layout = options.layout or "yoko"
  plain.setOptions(self, options)
end

return jplain

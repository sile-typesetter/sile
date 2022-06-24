-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = require("classes.plain")

local tplain = pl.class(plain)
tplain._name = "tplain"

tplain.defaultFrameset.content = {
  left = "8.3%pw",
  top = "11.6%ph",
  gridsize = 10,
  linegap = 7,
  linelength = 50,
  linecount = 30
}

function tplain:_t_common ()
  self:loadPackage("font-fallback")
  self:loadPackage("hanmenkyoshi")
  self:registerPostinit(function (class)
    class:bidiDisableTypesetter(SILE.typesetter)
    class:bidiDisableTypesetter(SILE.defaultTypesetter)
  end)
  self.defaultFrameset.content.tate = self.options.layout == "tate"
  self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
end

function tplain:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(tplain) end
  plain._init(self, options)
  tplain._t_common(self)
  return self
end

function tplain:declareOptions ()
  plain.declareOptions(self)
  self:declareOption("layout", function (_, value)
    if value then
      self.layout = value
      if value == "tate" then self:loadPackage("tate") end
    end
    return self.layout
  end)
end

function tplain:setOptions (options)
  options.layout = options.layout or "yoko"
  plain.setOptions(self, options)
end

return tplain

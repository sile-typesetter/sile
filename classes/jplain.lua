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
  end)
  self.defaultFrameset.content.tate = self.options.layout == "tate"
  self:declareHanmenFrame("content", self.defaultFrameset.content)
  SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
  if SILE.settings:get("document.language") ~= "ja" then
    SU.deprecated("document.language ≠ \"ja\" & jplain:…", nil, "0.14.0", "0.16.0", [[
  Prior to SILE v0.14.0, `jplain`, despite its name, enforced the
  language being set te Japanese. It no longer makes this assumption.
  To use a class like `jplain` for other languages, please base a
  *new* custom class inheriting from `jplain` rather than `jplain`
  directly. To use `jplain` for Japanese, you *must* specify
  \\language[main=ja]. (Also you'll probably want to set a font!)
    ]])
    SILE.languageSupport.loadLanguage("ja")
    SILE.settings:set("document.language", "ja", true)
    SILE.settings:set("font.family", "Noto Sans CJK JP", true)
  end
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

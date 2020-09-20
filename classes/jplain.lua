-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = SILE.require("plain", "classes")
local jplain = plain { id = "jplain"}

jplain:declareOption("layout", "yoko")

function jplain:init ()
  SILE.call("bidi-off")
  self:loadPackage("hanmenkyoshi")
  self:declareHanmenFrame( "content", {
    left = "8.3%pw", top = "11.6%ph",
    gridsize = 10, linegap = 7, linelength = 50,
    linecount = 30,
    tate = self.options.layout() == "tate"
  })
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames.content
  SILE.settings.set("document.parindent", SILE.nodefactory.glue("10pt"))
  return plain.init(self)
end

SILE.languageSupport.loadLanguage("ja")

return jplain

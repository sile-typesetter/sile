-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = SILE.require("plain", "classes")
local jplain = plain { id = "jplain", base = plain }

SILE.call("bidi-off")

jplain:declareOption("layout", "yoko")

jplain:loadPackage("hanmenkyoshi")
function jplain:init()
  self:declareHanmenFrame( "content", {
    left = "8.3%pw", top = "11.6%ph",
    gridsize = 10, linegap = 7, linelength = 50,
    linecount = 30,
    tate = self.options.layout() == "tate"
  })
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames.content
  return self.base:init()
end

SILE.languageSupport.loadLanguage("ja")
SILE.settings.set("document.parindent",SILE.nodefactory.newGlue("10pt"))
return jplain

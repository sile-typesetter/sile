-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = SILE.require("classes/plain");
local jplain = plain { id = "jplain", base = plain };
if not(SILE.scratch.headers) then SILE.scratch.headers = {}; end
jplain:loadPackage("hanmenkyoshi")
jplain:declareHanmenFrame( "content", {
  left = "8.3%", top = "11.6%", bottom = "90%",
  gridsize = 10, linegap = 7, linelength = 50, 
})
jplain.pageTemplate.firstContentFrame = jplain.pageTemplate.frames.content

SILE.languageSupport.loadLanguage("ja")
SILE.settings.set("document.parindent",SILE.nodefactory.newGlue("10pt"))
return jplain

local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "kn"

function language.declareSettings (_)
   -- TODO get this *unset* when switching to other languages
   SILE.settings:set("font.script", "Knda")
end

return language

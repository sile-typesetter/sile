local base = require("languages.base")

local language = pl.class(base)
language._name = "unicode"

function language:_post_init ()
   SU.error("got unicode nodemaker")
end

return language

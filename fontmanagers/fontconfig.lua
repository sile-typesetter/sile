local base = require("fontmanagers.base")

local fontmanager = pl.class(base)
fontmanager._name = "fontconfig"

function fontmanager:_init ()
   base._init(self)
   self._fc = require("justenoughfontconfig")
end

function fontmanager:face (options)
   return self._fc._face(options)
end

return fontmanager

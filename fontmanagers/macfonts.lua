local fontconfig = require("fontmanagers.base")

local fontmanager = pl.class(fontconfig)
fontmanager._name = "macfonts"

function fontmanager:_init ()
   self._mf = require("macfonts")
end

function fontmanager:face (options)
   return self._mf._face(options)
end

return fontmanager

local base = require("fontmanagers.base")

local fontmanager = pl.class(base)
fontmanager._name = "macfonts"

function fontmanager:_init ()
   base._init(self)
   self._mf = require("macfonts")
end

function fontmanager:face (options)
   return self._mf._face(options)
end

return fontmanager

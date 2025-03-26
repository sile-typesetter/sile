local base = require("typesetters.base")

local typesetter = pl.class(base)
typesetter._name = "latin-in-tate"

function typesetter:initFrame (frame)
   self.frame = frame
end

return typesetter

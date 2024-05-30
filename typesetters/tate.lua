local base = require("typesetters.firstfit")

local typesetter = pl.class(base)
typesetter._name = "tate"

function typesetter.leadingFor (_, v)
   v.height = SILE.length("1zw"):absolute()
   local bls = SILE.settings:get("document.baselineskip")
   local d = bls.height:absolute() - v.height
   local len = SILE.length(d.length, bls.height.stretch, bls.height.shrink)
   return SILE.nodefactory.vglue({ height = len })
end

return typesetter

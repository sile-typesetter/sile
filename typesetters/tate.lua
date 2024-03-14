local base = require("typesetters.firstfit")

local typesetter = pl.class(base)
typesetter._name = "tate"

function typesetter.leadingFor (_, v)
  v.height = SILE.types.length("1zw"):absolute()
  local bls = SILE.settings:get("document.baselineskip")
  local d = bls.height:absolute() - v.height
  local len = SILE.types.length(d.length, bls.height.stretch, bls.height.shrink)
  return SILE.types.node.vglue({ height = len })
end

return typesetter

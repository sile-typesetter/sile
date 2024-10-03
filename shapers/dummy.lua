local base = require("shapers.base")

local shaper = pl.class(base)
shaper._name = "dummy"

function shaper.addShapedGlyphToNnodeValue (_, _, _) end

function shaper.getFace () end

function shaper.createNnodes (_, _)
   return {}
end

function shaper.shapeToken (_, _, _)
   return {}
end

return shaper

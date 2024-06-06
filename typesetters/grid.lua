local base = require("typesetters.base")

local typesetter = pl.class(base)
typesetter._name = "grid"

local function makeUp (spacing, totals)
   local toadd = (spacing - SILE.types.measurement(totals.gridCursor)) % spacing
   totals.gridCursor = totals.gridCursor + toadd
   SU.debug("typesetter", "Makeup height =", toadd)
   return SILE.types.node.vglue({ discardable = false, gridleading = true, height = toadd })
end

function typesetter:_init (frame)
   base._init(self, frame)
   self.options = { spacing = SILE.types.measurement("1bs") }
end

function typesetter:leadingFor (vbox, previous)
   SU.debug("typesetter", "   Considering leading between two lines (grid mode):")
   SU.debug("typesetter", "   1)", previous)
   SU.debug("typesetter", "   2)", vbox)
   if not previous then
      return SILE.types.node.vglue()
   end
   SU.debug("typesetter", "   Depth of previous line was", previous.depth)
   local totals = self.frame.state.totals
   local oldCursor = SILE.types.measurement(totals.gridCursor)
   totals.gridCursor = oldCursor + vbox.height:absolute() + previous.depth
   SU.debug("typesetter", "   Cursor change =", totals.gridCursor - oldCursor)
   return makeUp(self.options.spacing, self.frame.state.totals)
end

function typesetter:pushVglue (spec)
   -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
   local node = SU.type(spec) == "vglue" and spec or SILE.types.node.vglue(spec)
   node.height.stretch = SILE.types.measurement()
   node.height.shrink = SILE.types.measurement()
   local totals = self.frame.state.totals
   totals.gridCursor = totals.gridCursor + SILE.types.measurement(node.height):absolute()
   self:pushVertical(node)
   self:pushVertical(makeUp(self.options.spacing, self.frame.state.totals))
   return node
end

function typesetter:pushExplicitVglue (spec)
   -- if SU.type(spec) ~= "table" then SU.warn("Please use pushVertical() to pass a premade node instead of a spec") end
   local node = SU.type(spec) == "vglue" and spec or SILE.types.node.vglue(spec)
   node.explicit = true
   node.discardable = false
   node.height.stretch = SILE.types.measurement()
   node.height.shrink = SILE.types.measurement()
   local totals = self.frame.state.totals
   totals.gridCursor = totals.gridCursor + SILE.types.measurement(node.height):absolute()
   self:pushVertical(node)
   self:pushVertical(makeUp(self.options.spacing, self.frame.state.totals))
   return node
end

return typesetter

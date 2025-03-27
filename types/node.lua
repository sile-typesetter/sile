--- SILE node type.
-- @types node

local nodetypes = {}

-- This infinity needs to be smaller than an actual infinity but bigger than the infinite stretch
-- added by the typesetter. See https://github.com/sile-typesetter/sile/issues/227
local infinity = SILE.types.measurement(1e13)

local function _maxnode (nodes, dim)
   local dims = SU.map(function (node)
      -- TODO there is a bug here because we shouldn't need to cast to lengths,
      -- somebody is setting a height as a number value (test in Lua 5.1)
      -- return node[dim]
      return SU.cast("length", node[dim])
   end, nodes)
   return SU.max(SILE.types.length(0), pl.utils.unpack(dims))
end

local _dims = pl.Set({ "width", "height", "depth" })

nodetypes.box = pl.class()
nodetypes.box.type = "special"

nodetypes.box.height = nil
nodetypes.box.depth = nil
nodetypes.box.width = nil
nodetypes.box.misfit = false
nodetypes.box.explicit = false
nodetypes.box.discardable = false
nodetypes.box.value = nil
nodetypes.box._default_length = "width"

function nodetypes.box:_init (spec)
   if
      type(spec) == "string"
      or type(spec) == "number"
      or SU.type(spec) == "measurement"
      or SU.type(spec) == "length"
   then
      self[self._default_length] = SU.cast("length", spec)
   elseif SU.type(spec) == "table" then
      if spec._tospec then
         spec = spec:_tospec()
      end
      for k, v in pairs(spec) do
         self[k] = _dims[k] and SU.cast("length", v) or v
      end
   elseif type(spec) ~= "nil" and SU.type(spec) ~= self.type then
      SU.error("Unimplemented, creating " .. self.type .. " node from " .. SU.type(spec), 1)
   end
   for dim in pairs(_dims) do
      if not self[dim] then
         self[dim] = SILE.types.length()
      end
   end
   self["is_" .. self.type] = true
   self.is_box = self.is_hbox or self.is_vbox or self.is_zerohbox or self.is_alternative or self.is_nnode
   self.is_zero = self.is_zerohbox or self.is_zerovglue
   if self.is_migrating then
      self.is_hbox, self.is_box = true, true
   end
end

-- De-init instances by shallow copying properties and removing meta table
function nodetypes.box:_tospec ()
   return pl.tablex.copy(self)
end

function nodetypes.box:tostring ()
   return self:__tostring()
end

function nodetypes.box:__tostring ()
   return self.type
end

function nodetypes.box.__concat (a, b)
   return tostring(a) .. tostring(b)
end

function nodetypes.box:absolute ()
   local clone = nodetypes[self.type](self:_tospec())
   for dim in pairs(_dims) do
      clone[dim] = self[dim]:absolute()
   end
   if self.nodes then
      clone.nodes = pl.tablex.map_named_method("absolute", self.nodes)
   end
   return clone
end

function nodetypes.box:lineContribution ()
   -- Regardless of the orientations, "width" is always in the
   -- writingDirection, and "height" is always in the "pageDirection"
   return self.misfit and self.height or self.width
end

function nodetypes.box:outputYourself ()
   SU.error(self.type .. " with no output routine")
end

function nodetypes.box:toText ()
   return self.type
end

function nodetypes.box:isBox ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "hbox"
      or self.type == "zerohbox"
      or self.type == "alternative"
      or self.type == "nnode"
      or self.type == "vbox"
end

function nodetypes.box:isNnode ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "nnode"
end

function nodetypes.box:isGlue ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "glue"
end

function nodetypes.box:isVglue ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "vglue"
end

function nodetypes.box:isZero ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "zerohbox" or self.type == "zerovglue"
end

function nodetypes.box:isUnshaped ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "unshaped"
end

function nodetypes.box:isAlternative ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "alternative"
end

function nodetypes.box:isVbox ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "vbox"
end

function nodetypes.box:isInsertion ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "insertion"
end

function nodetypes.box:isMigrating ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.migrating
end

function nodetypes.box:isPenalty ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "penalty"
end

function nodetypes.box:isDiscretionary ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "discretionary"
end

function nodetypes.box:isKern ()
   SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
   return self.type == "kern"
end

nodetypes.hbox = pl.class(nodetypes.box)
nodetypes.hbox.type = "hbox"

function nodetypes.hbox:_init (spec)
   nodetypes.box._init(self, spec)
end

function nodetypes.hbox:__tostring ()
   return "H<" .. tostring(self.width) .. ">^" .. tostring(self.height) .. "-" .. tostring(self.depth) .. "v"
end

function nodetypes.hbox:scaledWidth (line)
   return SU.rationWidth(self:lineContribution(), self.width, line.ratio)
end

function nodetypes.hbox:outputYourself (typesetter, line)
   local outputWidth = self:scaledWidth(line)
   if not self.value.glyphString then
      return
   end
   if typesetter.frame:writingDirection() == "RTL" then
      typesetter.frame:advanceWritingDirection(outputWidth)
   end
   SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
   SILE.outputter:setFont(self.value.options)
   SILE.outputter:drawHbox(self.value, outputWidth)
   if typesetter.frame:writingDirection() ~= "RTL" then
      typesetter.frame:advanceWritingDirection(outputWidth)
   end
end

nodetypes.zerohbox = pl.class(nodetypes.hbox)
nodetypes.zerohbox.type = "zerohbox"
nodetypes.zerohbox.value = { glyph = 0 }

nodetypes.nnode = pl.class(nodetypes.hbox)
nodetypes.nnode.type = "nnode"
nodetypes.nnode.language = ""
nodetypes.nnode.pal = nil
nodetypes.nnode.nodes = {}

function nodetypes.nnode:_init (spec)
   self:super(spec)
   if 0 == self.depth:tonumber() then
      self.depth = _maxnode(self.nodes, "depth")
   end
   if 0 == self.height:tonumber() then
      self.height = _maxnode(self.nodes, "height")
   end
   if 0 == self.width:tonumber() then
      self.width = SU.sum(SU.map(function (node)
         return node.width
      end, self.nodes))
   end
end

function nodetypes.nnode:__tostring ()
   return "N<"
      .. tostring(self.width)
      .. ">^"
      .. tostring(self.height)
      .. "-"
      .. tostring(self.depth)
      .. "v("
      .. self:toText()
      .. ")"
end

function nodetypes.nnode:absolute ()
   return self
end

function nodetypes.nnode:outputYourself (typesetter, line)
   -- See typesetter:computeLineRatio() which implements the currently rather messy
   -- and probably slightly dubious 'hyphenated' logic.
   -- Example: consider the word "out-put".
   -- The node queue therefore contains N(out)D(-)N(put) all pointing to the same
   -- parent N(output).
   if self.parent and not self.parent.hyphenated then
      -- When we hit N(out) and are not hyphenated, we output N(output) directly
      -- and mark it as used, so as to skip D(-)N(put) afterwards.
      -- I guess this was done to ensure proper kerning (vs. outputting each of
      -- the nodes separately).
      if not self.parent.used then
         self.parent:outputYourself(typesetter, line)
      end
      self.parent.used = true
   else
      -- It's possible not to have a parent, e.g. N(word) without hyphenation points.
      -- Either that, or we have a hyphenated parent but are in the case we are
      -- outputting one of the elements e.g. N(out)D(-) [line break] N(put).
      -- (ignoring the G(margin) nodes and potentially zerohbox nodes also on either side of the line break)
      for _, node in ipairs(self.nodes) do
         node:outputYourself(typesetter, line)
      end
   end
end

function nodetypes.nnode:toText ()
   return self.text
end

nodetypes.unshaped = pl.class(nodetypes.nnode)
nodetypes.unshaped.type = "unshaped"

function nodetypes.unshaped:_init (spec)
   self:super(spec)
   self.width = nil
end

function nodetypes.unshaped:__tostring ()
   return "U(" .. self:toText() .. ")"
end

getmetatable(nodetypes.unshaped).__index = function (_, _)
   -- if k == "width" then SU.error("Can't get width of unshaped node", true) end
   -- TODO: No idea why porting to proper Penlight classes this ^^^^^^ started
   -- killing everything. Perhaps because this function started working and would
   -- actually need to return rawget(self, k) or something?
end

function nodetypes.unshaped:shape ()
   local node = SILE.shaper:createNnodes(self.text, self.options)
   for i = 1, #node do
      node[i].parent = self.parent
   end
   return node
end

function nodetypes.unshaped.outputYourself (_)
   SU.error("An unshaped node made it to output", true)
end

nodetypes.discretionary = pl.class(nodetypes.hbox)

nodetypes.discretionary.type = "discretionary"
nodetypes.discretionary.prebreak = {}
nodetypes.discretionary.postbreak = {}
nodetypes.discretionary.replacement = {}
nodetypes.discretionary.used = false

function nodetypes.discretionary:__tostring ()
   return "D("
      .. SU.concat(self.prebreak, "")
      .. "|"
      .. SU.concat(self.postbreak, "")
      .. "|"
      .. SU.concat(self.replacement, "")
      .. ")"
end

function nodetypes.discretionary:toText ()
   return self.used and "-" or "_"
end

function nodetypes.discretionary:markAsPrebreak ()
   self.used = true
   if self.parent then
      self.parent.hyphenated = true
   end
   self.is_prebreak = true
end

function nodetypes.discretionary:cloneAsPostbreak ()
   if not self.used then
      SU.error("Cannot clone a non-used discretionary (previously marked as prebreak)")
   end
   return SILE.types.node.discretionary({
      prebreak = self.prebreak,
      postbreak = self.postbreak,
      replacement = self.replacement,
      parent = self.parent,
      used = true,
      is_prebreak = false,
   })
end

function nodetypes.discretionary:outputYourself (typesetter, line)
   -- See typesetter:computeLineRatio() which implements the currently rather
   -- messy hyphenated checks.
   -- Example: consider the word "out-put-ter".
   -- The node queue contains N(out)D(-)N(put)D(-)N(ter) all pointing to the same
   -- parent N(output), and here we hit D(-)

   -- Non-hyphenated parent: when N(out) was hit, we went for outputting
   -- the whole parent, so all other elements must now be skipped.
   if self.parent and not self.parent.hyphenated then
      return
   end

   -- It's possible not to have a parent (e.g. on a discretionary directly
   -- added in the queue and not coming from the hyphenator logic).
   -- Eiher that, or we have a hyphenated parent.
   if self.used then
      -- This is the actual hyphenation point.
      if self.is_prebreak then
         for _, node in ipairs(self.prebreak) do
            node:outputYourself(typesetter, line)
         end
      else
         for _, node in ipairs(self.postbreak) do
            node:outputYourself(typesetter, line)
         end
      end
   else
      -- This is not the hyphenation point (but another discretionary in the queue)
      -- E.g. we were in the case where we have N(out)D(-) [line break] N(out)D(-)N(ter)
      -- and now hit the second D(-).
      -- Unused discretionaries are obviously replaced.
      for _, node in ipairs(self.replacement) do
         node:outputYourself(typesetter, line)
      end
   end
end

function nodetypes.discretionary:prebreakWidth ()
   if self.prebw then
      return self.prebw
   end
   self.prebw = SILE.types.length()
   for _, node in ipairs(self.prebreak) do
      self.prebw:___add(node.width)
   end
   return self.prebw
end

function nodetypes.discretionary:postbreakWidth ()
   if self.postbw then
      return self.postbw
   end
   self.postbw = SILE.types.length()
   for _, node in ipairs(self.postbreak) do
      self.postbw:___add(node.width)
   end
   return self.postbw
end

function nodetypes.discretionary:replacementWidth ()
   if self.replacew then
      return self.replacew
   end
   self.replacew = SILE.types.length()
   for _, node in ipairs(self.replacement) do
      self.replacew:___add(node.width)
   end
   return self.replacew
end

function nodetypes.discretionary:prebreakHeight ()
   if self.prebh then
      return self.prebh
   end
   self.prebh = _maxnode(self.prebreak, "height")
   return self.prebh
end

function nodetypes.discretionary:postbreakHeight ()
   if self.postbh then
      return self.postbh
   end
   self.postbh = _maxnode(self.postbreak, "height")
   return self.postbh
end

function nodetypes.discretionary:replacementHeight ()
   if self.replaceh then
      return self.replaceh
   end
   self.replaceh = _maxnode(self.replacement, "height")
   return self.replaceh
end

function nodetypes.discretionary:replacementDepth ()
   if self.replaced then
      return self.replaced
   end
   self.replaced = _maxnode(self.replacement, "depth")
   return self.replaced
end

nodetypes.alternative = pl.class(nodetypes.hbox)

nodetypes.alternative.type = "alternative"
nodetypes.alternative.options = {}
nodetypes.alternative.selected = nil

function nodetypes.alternative:__tostring ()
   return "A(" .. SU.concat(self.options, " / ") .. ")"
end

function nodetypes.alternative:minWidth ()
   local minW = function (a, b)
      return SU.min(a.width, b.width)
   end
   return pl.tablex.reduce(minW, self.options)
end

function nodetypes.alternative:deltas ()
   local minWidth = self:minWidth()
   local rv = {}
   for i = 1, #self.options do
      rv[#rv + 1] = self.options[i].width - minWidth
   end
   return rv
end

function nodetypes.alternative:outputYourself (typesetter, line)
   if self.selected then
      self.options[self.selected]:outputYourself(typesetter, line)
   end
end

nodetypes.glue = pl.class(nodetypes.box)
nodetypes.glue.type = "glue"
nodetypes.glue.discardable = true

function nodetypes.glue:__tostring ()
   return (self.explicit and "E:" or "") .. "G<" .. tostring(self.width) .. ">"
end

function nodetypes.glue.toText (_)
   return " "
end

function nodetypes.glue:outputYourself (typesetter, line)
   local outputWidth = SU.rationWidth(self.width:absolute(), self.width:absolute(), line.ratio)
   typesetter.frame:advanceWritingDirection(outputWidth)
end

-- A hfillglue is just a glue with infinite stretch.
-- (Convenience so callers do not have to know what infinity is.)
nodetypes.hfillglue = pl.class(nodetypes.glue)
function nodetypes.hfillglue:_init (spec)
   self:super(spec)
   self.width = SILE.types.length(self.width.length, infinity, self.width.shrink)
end

-- A hssglue is just a glue with infinite stretch and shrink.
-- (Convenience so callers do not have to know what infinity is.)
nodetypes.hssglue = pl.class(nodetypes.glue)
function nodetypes.hssglue:_init (spec)
   self:super(spec)
   self.width = SILE.types.length(self.width.length, infinity, infinity)
end

nodetypes.kern = pl.class(nodetypes.glue)
nodetypes.kern.type = "kern" -- Perhaps some smell here, see comment on vkern
nodetypes.kern.discardable = false

function nodetypes.kern:__tostring ()
   return "K<" .. tostring(self.width) .. ">"
end

nodetypes.vglue = pl.class(nodetypes.box)
nodetypes.vglue.type = "vglue"
nodetypes.vglue.discardable = true
nodetypes.vglue._default_length = "height"
nodetypes.vglue.adjustment = nil

function nodetypes.vglue:_init (spec)
   self.adjustment = SILE.types.measurement()
   self:super(spec)
end

function nodetypes.vglue:__tostring ()
   return (self.explicit and "E:" or "") .. "VG<" .. tostring(self.height) .. ">"
end

function nodetypes.vglue:adjustGlue (adjustment)
   self.adjustment = adjustment
end

function nodetypes.vglue:outputYourself (typesetter, line)
   typesetter.frame:advancePageDirection(line.height:absolute() + line.depth:absolute() + self.adjustment)
end

function nodetypes.vglue:unbox ()
   return { self }
end

-- A vfillglue is just a vglue with infinite stretch.
-- (Convenience so callers do not have to know what infinity is.)
nodetypes.vfillglue = pl.class(nodetypes.vglue)
function nodetypes.vfillglue:_init (spec)
   self:super(spec)
   self.height = SILE.types.length(self.width.length, infinity, self.width.shrink)
end

-- A vssglue is just a vglue with infinite stretch and shrink.
-- (Convenience so callers do not have to know what infinity is.)
nodetypes.vssglue = pl.class(nodetypes.vglue)
function nodetypes.vssglue:_init (spec)
   self:super(spec)
   self.height = SILE.types.length(self.width.length, infinity, infinity)
end

nodetypes.zerovglue = pl.class(nodetypes.vglue)

nodetypes.vkern = pl.class(nodetypes.vglue)
-- FIXME TODO
-- Here we cannot do:
--   nodetypes.vkern.type = "vkern"
-- It cannot be typed as "vkern" as the pagebuilder doesn't check is_vkern.
-- So it's just a vglue currrenty, marked as not discardable...
-- But on the other hand, nodetypes.kern is typed "kern" and is not a glue...
-- Frankly, the discardable/explicit flags and the types are too
-- entangled and point towards a more general design issue.
-- N.B. this vkern node is only used in the linespacing package so far.
nodetypes.vkern.discardable = false

function nodetypes.vkern:__tostring ()
   return "VK<" .. tostring(self.height) .. ">"
end

nodetypes.penalty = pl.class(nodetypes.box)
nodetypes.penalty.type = "penalty"
nodetypes.penalty.discardable = true
nodetypes.penalty.penalty = 0

function nodetypes.penalty:_init (spec)
   self:super(spec)
   if type(spec) ~= "table" then
      self.penalty = SU.cast("number", spec)
   end
end

function nodetypes.penalty:__tostring ()
   return "P(" .. tostring(self.penalty) .. ")"
end

function nodetypes.penalty.outputYourself (_) end

function nodetypes.penalty.toText (_)
   return "(!)"
end

function nodetypes.penalty:unbox ()
   return { self }
end

nodetypes.vbox = pl.class(nodetypes.box)
nodetypes.vbox.type = "vbox"
nodetypes.vbox.nodes = {}
nodetypes.vbox._default_length = "height"

function nodetypes.vbox:_init (spec)
   self.nodes = {}
   self:super(spec)
   self.depth = _maxnode(self.nodes, "depth")
   self.height = _maxnode(self.nodes, "height")
end

function nodetypes.vbox:__tostring ()
   return "VB<" .. tostring(self.height) .. "|" .. self:toText() .. "v" .. tostring(self.depth) .. ")"
end

function nodetypes.vbox:toText ()
   return "VB["
      .. SU.concat(
         SU.map(function (node)
            return node:toText()
         end, self.nodes),
         ""
      )
      .. "]"
end

function nodetypes.vbox:outputYourself (typesetter, line)
   typesetter.frame:advancePageDirection(self.height)
   local initial = true
   for _, node in ipairs(self.nodes) do
      if not (initial and (node.is_glue or node.is_penalty)) then
         initial = false
         node:outputYourself(typesetter, line)
      end
   end
   typesetter.frame:advancePageDirection(self.depth)
   typesetter.frame:newLine()
end

function nodetypes.vbox:unbox ()
   for i = 1, #self.nodes do
      if self.nodes[i].is_vbox or self.nodes[i].is_vglue then
         return self.nodes
      end
   end
   return { self }
end

function nodetypes.vbox:append (box)
   local nodes = box
   if not box then
      SU.error("nil box given", true)
   end
   if nodes.type then
      nodes = box:unbox()
   end
   self.height = self.height:absolute()
   self.height:___add(self.depth)
   local lastdepth = SILE.types.length()
   for i = 1, #nodes do
      table.insert(self.nodes, nodes[i])
      self.height:___add(nodes[i].height)
      self.height:___add(nodes[i].depth:absolute())
      if nodes[i].is_vbox then
         lastdepth = nodes[i].depth
      end
   end
   self.height:___sub(lastdepth)
   self.ratio = 1
   self.depth = lastdepth
end

nodetypes.migrating = pl.class(nodetypes.hbox)
nodetypes.migrating.type = "migrating"
nodetypes.migrating.material = {}
nodetypes.migrating.value = {}
nodetypes.migrating.nodes = {}

function nodetypes.migrating:__tostring ()
   return "<M: " .. tostring(self.material) .. ">"
end

return nodetypes

local nodefactory = {}

-- This infinity needs to be smaller than an actual infinity but bigger than the infinite stretch
-- added by the typesetter. See https://github.com/sile-typesetter/sile/issues/227
local infinity = SILE.measurement(1e13)

local function _maxnode (nodes, dim)
  local dims = SU.map(function (node)
    -- TODO there is a bug here because we shouldn't need to cast to lengths,
    -- somebody is setting a height as a number value (test in Lua 5.1)
    -- return node[dim]
    return SU.cast("length", node[dim])
  end, nodes)
  return SU.max(SILE.length(0), pl.utils.unpack(dims))
end

local _dims = pl.Set { "width", "height", "depth" }

nodefactory.box = pl.class()
nodefactory.box.type = "special"

nodefactory.box.height = nil
nodefactory.box.depth = nil
nodefactory.box.width = nil
nodefactory.box.misfit = false
nodefactory.box.explicit = false
nodefactory.box.discardable = false
nodefactory.box.value = nil
nodefactory.box._default_length = "width"

function nodefactory.box:_init (spec)
  if type(spec) == "string"
    or type(spec) == "number"
    or SU.type(spec) == "measurement"
    or SU.type(spec) == "length" then
    self[self._default_length] = SU.cast("length", spec)
  elseif SU.type(spec) == "table" then
    if spec._tospec then spec = spec:_tospec() end
    for k, v in pairs(spec) do
      self[k] = _dims[k] and SU.cast("length", v) or v
    end
  elseif type(spec) ~= "nil" and SU.type(spec) ~= self.type then
    SU.error("Unimplemented, creating " .. self.type .. " node from " .. SU.type(spec), 1)
  end
  for dim in pairs(_dims) do
    if not self[dim] then self[dim] = SILE.length() end
  end
  self["is_"..self.type] = true
  self.is_box = self.is_hbox or self.is_vbox or self.is_zerohbox or self.is_alternative or self.is_nnode
  self.is_zero = self.is_zerohbox or self.is_zerovglue
  if self.is_migrating then self.is_hbox, self.is_box = true, true end
end

-- De-init instances by shallow copying properties and removing meta table
function nodefactory.box:_tospec ()
  return pl.tablex.copy(self)
end

function nodefactory.box:tostring ()
  return  self:__tostring()
end

function nodefactory.box:__tostring ()
  return self.type
end

function nodefactory.box.__concat (a, b)
  return tostring(a) .. tostring(b)
end

function nodefactory.box:absolute ()
  local clone = nodefactory[self.type](self:_tospec())
  for dim in pairs(_dims) do
    clone[dim] = self[dim]:absolute()
  end
  if self.nodes then
    clone.nodes = pl.tablex.map_named_method("absolute", self.nodes)
  end
  return clone
end

function nodefactory.box:lineContribution ()
  -- Regardless of the orientations, "width" is always in the
  -- writingDirection, and "height" is always in the "pageDirection"
  return self.misfit and self.height or self.width
end

function nodefactory.box:outputYourself ()
  SU.error(self.type.." with no output routine")
end

function nodefactory.box:toText ()
  return self.type
end

function nodefactory.box:isBox ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "hbox" or self.type == "zerohbox" or self.type == "alternative" or self.type == "nnode" or self.type == "vbox"
end

function nodefactory.box:isNnode ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type=="nnode"
end

function nodefactory.box:isGlue ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "glue"
end

function nodefactory.box:isVglue ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "vglue"
end

function nodefactory.box:isZero ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "zerohbox" or self.type == "zerovglue"
end

function nodefactory.box:isUnshaped ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "unshaped"
end

function nodefactory.box:isAlternative ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "alternative"
end

function nodefactory.box:isVbox ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "vbox"
end

function nodefactory.box:isInsertion ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "insertion"
end

function nodefactory.box:isMigrating ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.migrating
end

function nodefactory.box:isPenalty ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "penalty"
end

function nodefactory.box:isDiscretionary ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "discretionary"
end

function nodefactory.box:isKern ()
  SU.warn("Deprecated function, please use boolean is_<type> property to check types", true)
  return self.type == "kern"
end

nodefactory.hbox = pl.class(nodefactory.box)
nodefactory.hbox.type = "hbox"

function nodefactory.hbox:_init (spec)
  nodefactory.box._init(self, spec)
end

function nodefactory.hbox:__tostring ()
  return "H<" .. tostring(self.width) .. ">^" .. tostring(self.height) .. "-" .. tostring(self.depth) .. "v"
end

function nodefactory.hbox:scaledWidth (line)
  return SU.rationWidth(self:lineContribution(), self.width, line.ratio)
end

function nodefactory.hbox:outputYourself (typesetter, line)
  local outputWidth = self:scaledWidth(line)
  if not self.value.glyphString then return end
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

nodefactory.zerohbox = pl.class(nodefactory.hbox)
nodefactory.zerohbox.type = "zerohbox"
nodefactory.zerohbox.value = { glyph = 0 }

nodefactory.nnode = pl.class(nodefactory.hbox)
nodefactory.nnode.type = "nnode"
nodefactory.nnode.language = ""
nodefactory.nnode.pal = nil
nodefactory.nnode.nodes = {}

function nodefactory.nnode:_init (spec)
  self:super(spec)
  if 0 == self.depth:tonumber() then self.depth = _maxnode(self.nodes, "depth")  end
  if 0 == self.height:tonumber() then self.height = _maxnode(self.nodes, "height") end
  if 0 == self.width:tonumber() then self.width = SU.sum(SU.map(function (node) return node.width end, self.nodes)) end
end

function nodefactory.nnode:__tostring ()
  return "N<" .. tostring(self.width) .. ">^" .. tostring(self.height) .. "-" .. tostring(self.depth) .. "v(" .. self:toText() .. ")"
end

function nodefactory.nnode:absolute ()
  return self
end

function nodefactory.nnode:outputYourself (typesetter, line)
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
    for _, node in ipairs(self.nodes) do node:outputYourself(typesetter, line) end
  end
end

function nodefactory.nnode:toText ()
  return self.text
end

nodefactory.unshaped = pl.class(nodefactory.nnode)
nodefactory.unshaped.type = "unshaped"

function nodefactory.unshaped:_init (spec)
  self:super(spec)
  self.width = nil
end

function nodefactory.unshaped:__tostring ()
  return "U(" .. self:toText() .. ")";
end

getmetatable(nodefactory.unshaped).__index = function (_, _)
  -- if k == "width" then SU.error("Can't get width of unshaped node", true) end
  -- TODO: No idea why porting to proper Penlight classes this ^^^^^^ started
  -- killing everything. Perhaps becaus this function started working and would
  -- actually need to return rawget(self, k) or something?
end

function nodefactory.unshaped:shape ()
  local node =  SILE.shaper:createNnodes(self.text, self.options)
  for i=1, #node do
    node[i].parent = self.parent
  end
  return node
end

function nodefactory.unshaped.outputYourself (_)
  SU.error("An unshaped node made it to output", true)
end

nodefactory.discretionary = pl.class(nodefactory.hbox)

nodefactory.discretionary.type = "discretionary"
nodefactory.discretionary.prebreak = {}
nodefactory.discretionary.postbreak = {}
nodefactory.discretionary.replacement = {}
nodefactory.discretionary.used = false

function nodefactory.discretionary:__tostring ()
  return "D(" .. SU.concat(self.prebreak, "") .. "|" .. SU.concat(self.postbreak, "") .."|" .. SU.concat(self.replacement, "") .. ")";
end

function nodefactory.discretionary:toText ()
  return self.used and "-" or "_"
end

function nodefactory.discretionary:outputYourself (typesetter, line)
  -- See typesetter:computeLineRatio() which implements the currently rather
  -- messy hyphenated checks.
  -- Example: consider the word "out-put-ter".
  -- The node queue contains N(out)D(-)N(put)D(-)N(ter) all pointing to the same
  -- parent N(output), and here we hit D(-)

  -- Non-hyphenated parent: when N(out) was hit, we went for outputting
  -- the whole parent, so all other elements must now be skipped.
  if self.parent and not self.parent.hyphenated then return end

  -- It's possible not to have a parent (e.g. on a discretionary directly
  -- added in the queue and not coming from the hyphenator logic).
  -- Eiher that, or we have a hyphenate parent.
  if self.used then
    -- This is the actual hyphenation point.
    -- Skip margin glue and zero boxes.
    -- If we then reach our discretionary, it means its the first in the line,
    -- i.e. a postbreak. Otherwise, its a prebreak (near the end of the line,
    -- notwithstanding glues etc.)
    local i = 1
    while (line.nodes[i].is_glue and line.nodes[i].value == "margin")
      or line.nodes[i].type == "zerohbox" do
      i = i + 1
    end
    if (line.nodes[i] == self) then
      for _, node in ipairs(self.postbreak) do node:outputYourself(typesetter, line) end
    else
      for _, node in ipairs(self.prebreak) do node:outputYourself(typesetter, line) end
    end
  else
    -- This is not the hyphenation point (but another discretionary in the queue)
    -- E.g. we were in the case where we have N(out)D(-) [line break] N(out)D(-)N(ter)
    -- and now hit the second D(-).
    -- Unused discretionaries are obviously replaced.
    for _, node in ipairs(self.replacement) do node:outputYourself(typesetter, line) end
  end
end

function nodefactory.discretionary:prebreakWidth ()
  if self.prebw then return self.prebw end
  self.prebw = SILE.length()
  for _, node in ipairs(self.prebreak) do self.prebw:___add(node.width) end
  return self.prebw
end

function nodefactory.discretionary:postbreakWidth ()
  if self.postbw then return self.postbw end
  self.postbw = SILE.length()
  for _, node in ipairs(self.postbreak) do self.postbw:___add(node.width) end
  return self.postbw
end

function nodefactory.discretionary:replacementWidth ()
  if self.replacew then return self.replacew end
  self.replacew = SILE.length()
  for _, node in ipairs(self.replacement) do self.replacew:___add(node.width) end
  return self.replacew
end

function nodefactory.discretionary:prebreakHeight ()
  if self.prebh then return self.prebh end
  self.prebh = _maxnode(self.prebreak, "height")
  return self.prebh
end

function nodefactory.discretionary:postbreakHeight ()
  if self.postbh then return self.postbh end
  self.postbh = _maxnode(self.postbreak, "height")
  return self.postbh
end

function nodefactory.discretionary:replacementHeight ()
  if self.replaceh then return self.replaceh end
  self.replaceh = _maxnode(self.replacement, "height")
  return self.replaceh
end

function nodefactory.discretionary:replacementDepth ()
  if self.replaced then return self.replaced end
  self.replaced = _maxnode(self.replacement, "depth")
  return self.replaced
end

nodefactory.alternative = pl.class(nodefactory.hbox)

nodefactory.alternative.type = "alternative"
nodefactory.alternative.options = {}
nodefactory.alternative.selected = nil

function nodefactory.alternative:__tostring ()
  return "A(" .. SU.concat(self.options, " / ") .. ")"
end

function nodefactory.alternative:minWidth ()
  local minW = function (a, b) return SU.min(a.width, b.width) end
  return pl.tablex.reduce(minW, self.options)
end

function nodefactory.alternative:deltas ()
  local minWidth = self:minWidth()
  local rv = {}
  for i = 1, #self.options do rv[#rv+1] = self.options[i].width - minWidth end
  return rv
end

function nodefactory.alternative:outputYourself (typesetter, line)
  if self.selected then
    self.options[self.selected]:outputYourself(typesetter, line)
  end
end

nodefactory.glue = pl.class(nodefactory.box)
nodefactory.glue.type = "glue"
nodefactory.glue.discardable = true

function nodefactory.glue:__tostring ()
  return (self.explicit and "E:" or "") .. "G<" .. tostring(self.width) .. ">"
end

function nodefactory.glue.toText (_)
  return " "
end

function nodefactory.glue:outputYourself (typesetter, line)
  local outputWidth = SU.rationWidth(self.width:absolute(), self.width:absolute(), line.ratio)
  typesetter.frame:advanceWritingDirection(outputWidth)
end

-- A hfillglue is just a glue with infinite stretch.
-- (Convenience so callers do not have to know what infinity is.)
nodefactory.hfillglue = pl.class(nodefactory.glue)
function nodefactory.hfillglue:_init (spec)
  self:super(spec)
  self.width = SILE.length(self.width.length, infinity, self.width.shrink)
end

-- A hssglue is just a glue with infinite stretch and shrink.
-- (Convenience so callers do not have to know what infinity is.)
nodefactory.hssglue = pl.class(nodefactory.glue)
function nodefactory.hssglue:_init (spec)
  self:super(spec)
  self.width = SILE.length(self.width.length, infinity, infinity)
end

nodefactory.kern = pl.class(nodefactory.glue)
nodefactory.kern.type = "kern" -- Perhaps some smell here, see comment on vkern
nodefactory.kern.discardable = false

function nodefactory.kern:__tostring ()
  return "K<" .. tostring(self.width) .. ">"
end

nodefactory.vglue = pl.class(nodefactory.box)
nodefactory.vglue.type = "vglue"
nodefactory.vglue.discardable = true
nodefactory.vglue._default_length = "height"
nodefactory.vglue.adjustment = nil

function nodefactory.vglue:_init (spec)
  self.adjustment = SILE.measurement()
  self:super(spec)
end

function nodefactory.vglue:__tostring ()
  return (self.explicit and "E:" or "") .. "VG<" .. tostring(self.height) .. ">";
end

function nodefactory.vglue:adjustGlue (adjustment)
  self.adjustment = adjustment
end

function nodefactory.vglue:outputYourself (typesetter, line)
  typesetter.frame:advancePageDirection(line.height:absolute() + line.depth:absolute() + self.adjustment)
end

function nodefactory.vglue:unbox ()
  return { self }
end

-- A vfillglue is just a vglue with infinite stretch.
-- (Convenience so callers do not have to know what infinity is.)
nodefactory.vfillglue = pl.class(nodefactory.vglue)
function nodefactory.vfillglue:_init (spec)
  self:super(spec)
  self.height = SILE.length(self.width.length, infinity, self.width.shrink)
end

-- A vssglue is just a vglue with infinite stretch and shrink.
-- (Convenience so callers do not have to know what infinity is.)
nodefactory.vssglue = pl.class(nodefactory.vglue)
function nodefactory.vssglue:_init (spec)
  self:super(spec)
  self.height = SILE.length(self.width.length, infinity, infinity)
end

nodefactory.zerovglue = pl.class(nodefactory.vglue)

nodefactory.vkern = pl.class(nodefactory.vglue)
-- FIXME TODO
-- Here we cannot do:
--   nodefactory.vkern.type = "vkern"
-- It cannot be typed as "vkern" as the pagebuilder doesn't check is_vkern.
-- So it's just a vglue currrenty, marked as not discardable...
-- But on the other hand, nodefactory.kern is typed "kern" and is not a glue...
-- Frankly, the discardable/explicit flags and the types are too
-- entangled and point towards a more general design issue.
-- N.B. this vkern node is only used in the linespacing package so far.
nodefactory.vkern.discardable = false

function nodefactory.vkern:__tostring ()
  return "VK<" .. tostring(self.height) .. ">"
end

nodefactory.penalty = pl.class(nodefactory.box)
nodefactory.penalty.type = "penalty"
nodefactory.penalty.discardable = true
nodefactory.penalty.penalty = 0

function nodefactory.penalty:_init (spec)
  self:super(spec)
  if type(spec) ~= "table" then
    self.penalty = SU.cast("number", spec)
  end
end

function nodefactory.penalty:__tostring ()
  return "P(" .. tostring(self.penalty) .. ")";
end

function nodefactory.penalty.outputYourself (_)
end

function nodefactory.penalty.toText (_)
  return "(!)"
end

function nodefactory.penalty:unbox ()
  return { self }
end

nodefactory.vbox = pl.class(nodefactory.box)
nodefactory.vbox.type = "vbox"
nodefactory.vbox.nodes = {}
nodefactory.vbox._default_length = "height"

function nodefactory.vbox:_init (spec)
  self.nodes = {}
  self:super(spec)
  self.depth = _maxnode(self.nodes, "depth")
  self.height = _maxnode(self.nodes, "height")
end

function nodefactory.vbox:__tostring ()
  return "VB<" .. tostring(self.height) .. "|" .. self:toText() .. "v".. tostring(self.depth) ..")";
end

function nodefactory.vbox:toText ()
  return "VB[" .. SU.concat(SU.map(function (node) return node:toText() end, self.nodes), "") .. "]"
end

function nodefactory.vbox:outputYourself (typesetter, line)
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

function nodefactory.vbox:unbox ()
  for i = 1, #self.nodes do
    if self.nodes[i].is_vbox or self.nodes[i].is_vglue then return self.nodes end
  end
  return {self}
end

function nodefactory.vbox:append (box)
  local nodes = box
  if not box then SU.error("nil box given", true) end
  if nodes.type then
    nodes = box:unbox()
  end
  self.height = self.height:absolute()
  self.height:___add(self.depth)
  local lastdepth = SILE.length()
  for i = 1, #nodes do
    table.insert(self.nodes, nodes[i])
    self.height:___add(nodes[i].height)
    self.height:___add(nodes[i].depth:absolute())
    if nodes[i].is_vbox then lastdepth = nodes[i].depth end
  end
  self.height:___sub(lastdepth)
  self.ratio = 1
  self.depth = lastdepth
end

nodefactory.migrating = pl.class(nodefactory.hbox)
nodefactory.migrating.type = "migrating"
nodefactory.migrating.material = {}
nodefactory.migrating.value = {}
nodefactory.migrating.nodes = {}

function nodefactory.migrating:__tostring ()
  return "<M: " .. tostring(self.material) .. ">"
end

local _deprecated_nodefactory = {}

_deprecated_nodefactory.newHbox = function (spec)
  return nodefactory.hbox(spec)
end

_deprecated_nodefactory.newNnode = function (spec)
  return nodefactory.nnode(spec)
end

_deprecated_nodefactory.newUnshaped = function (spec)
  return nodefactory.unshaped(spec)
end

_deprecated_nodefactory.newDisc = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.disc = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.newAlternative = function (spec)
  return nodefactory.alternative(spec)
end

_deprecated_nodefactory.newGlue = function (spec)
  return nodefactory.glue(spec)
end

_deprecated_nodefactory.newKern = function (spec)
  return nodefactory.kern(spec)
end

_deprecated_nodefactory.newVglue = function (spec)
  return nodefactory.vglue(spec)
end

_deprecated_nodefactory.newVKern = function (spec)
  return nodefactory.vkern(spec)
end

_deprecated_nodefactory.newPenalty = function (spec)
  return nodefactory.penalty(spec)
end

_deprecated_nodefactory.newDiscretionary = function (spec)
  return nodefactory.discretionary(spec)
end

_deprecated_nodefactory.newVbox = function (spec)
  return nodefactory.vbox(spec)
end

_deprecated_nodefactory.newMigrating = function (spec)
  return nodefactory.migrating(spec)
end

_deprecated_nodefactory.zeroGlue = function ()
  return nodefactory.glue()
end

_deprecated_nodefactory.hfillGlue = function ()
  return nodefactory.hfillglue()
end

_deprecated_nodefactory.vfillGlue = function ()
  return nodefactory.vfillglue()
end

_deprecated_nodefactory.hssGlue = function ()
  return nodefactory.hssglue()
end

_deprecated_nodefactory.vssGlue = function ()
  return nodefactory.vssglue()
end

_deprecated_nodefactory.zeroHbox = function ()
  return nodefactory.zerohbox()
end

_deprecated_nodefactory.zeroVglue = function ()
  return nodefactory.zerovglue()
end

setmetatable(nodefactory, {
    __index = function (_, prop)
      if _deprecated_nodefactory[prop] then
        SU.deprecated("SILE.nodefactory." .. prop, "SILE.nodefactory." .. prop:match("n?e?w?(.*)"):lower(), "0.10.0", "0.14.0")
      elseif type(prop) == "number" then -- luacheck: ignore 542
        -- Likely at attempt to iterate (or dump) the table, sort of safe to ignore
      else
        SU.error("Attempt to access non-existent SILE.nodefactory." .. prop)
      end
    end
  })

return nodefactory

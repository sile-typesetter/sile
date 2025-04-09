--- This module defines the standard node classes used in SILE.
-- Some packages or other modules may define their own node classes for specific purposes,
-- but this does not have to be covered here.
--
-- @module SILE.types.node

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

--- Base abstract box class used by the other box types.
--
-- Other node classes derive from it, adding or overriding properties and methods.
-- It should not be used directly.
--
-- @type box

local box = pl.class()
box.type = "special"

box.height = nil
box.depth = nil
box.width = nil
box.orthogonal = false
box.explicit = false
box.discardable = false
box.value = nil
box._default_length = "width"

--- Constructor
-- @tparam table spec A table with the properties of the box.
function box:_init (spec)
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
function box:_tospec ()
   return pl.tablex.copy(self)
end

function box:tostring ()
   return self:__tostring()
end

function box:__tostring ()
   return self.type
end

function box.__concat (a, b)
   return tostring(a) .. tostring(b)
end

--- Create an absolute version of the box.
-- All Dimensions are based absolute (i.e. in points)
--
-- @treturn box A new box with the same properties as the original, but with absolute dimensions.
function box:absolute ()
   local clone = self._class(self:_tospec())
   for dim in pairs(_dims) do
      clone[dim] = self[dim]:absolute()
   end
   if self.nodes then
      clone.nodes = pl.tablex.map_named_method("absolute", self.nodes)
   end
   return clone
end

--- Returns either the width or the height of the box.
-- Regardless of the orientations, "width" is always in the writingDirection,
-- and "height" is always in the "pageDirection"
--
-- @treturn SILE.types.length  The width or height of the box, depending on the orientation.
function box:lineContribution ()
   return self.orthogonal and self.height or self.width
end

--- Output routine for a box.
-- This is an abstract method that must be overridden by subclasses.
--
function box:outputYourself (_, _)
   SU.error(self.type .. " with no output routine")
end

--- Returns a text description of the box for debugging purposes.
-- @treturn string A string representation of the box.
function box:toText ()
   return self.type
end

--- A hbox is a box node used in horizontal mode.
--
-- Derived from `box`.
--
-- Properties is_hbox and is_box are true.
--
-- @type hbox

local hbox = pl.class(box)
hbox.type = "hbox"

--- Constructor
--
-- @tparam table spec A table with the properties of the hbox.
function hbox:_init (spec)
   box._init(self, spec)
end

function hbox:__tostring ()
   return "H<" .. tostring(self.width) .. ">^" .. tostring(self.height) .. "-" .. tostring(self.depth) .. "v"
end

--- Returns the width of the hbox, scaled by the line ratio.
-- This is used to determine the width of the hbox when it is output.
--
-- @tparam table line The line properties (notably ratio)
-- @treturn SILE.types.length The scaled width of the hbox.
function hbox:scaledWidth (line)
   return SU.rationWidth(self:lineContribution(), self.width, line.ratio)
end

--- ôutput routine for a hbox.
--
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably ratio)
function hbox:outputYourself (typesetter, line)
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

--- A zerohbox is a special-kind of hbox with zero width, height and depth.
--
-- Derived from `hbox`.
--
-- Properties is_zerohbox (and convenience is_zero) and is_box are true.
-- Note that is_hbox is NOT true: zerohbox are used in a specific context
--
-- @type zerohbox
local zerohbox = pl.class(hbox)
zerohbox.type = "zerohbox"
zerohbox.value = { glyph = 0 }

--- A nnode is a node representing text content.
--
-- Derived from `hbox`.
--
-- Properties is_nnode and is_box are true.
--
-- @type nnode
local nnode = pl.class(hbox)
nnode.type = "nnode"
nnode.language = ""
nnode.pal = nil
nnode.nodes = {}

--- Constructor
-- @tparam table spec A table with the properties of the nnode.
function nnode:_init (spec)
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

function nnode:__tostring ()
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

--- Create an absolute version of the box.
-- This overrides the base class method as nnode content is assumed to in points already.
--
-- @treturn box The box itself.
function nnode:absolute ()
   return self
end

--- Output routine for a nnode.
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably ratio)
function nnode:outputYourself (typesetter, line)
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

--- Returns the text content of the nnode.
-- Contrary to the parent class, this is the actual text content of the node,
-- not a text representation of the node.
--
-- @treturn string The text content of the nnode.
function nnode:toText ()
   return self.text
end

--- An unshaped node is a text node that has not been shaped yet.
--
-- Derived from `nnode`.
--
-- Properties is_unshaped is true.
-- Note that is_nnode is NOT true, as an unshaped node is not a representable node yet.
--
-- @type unshaped

local unshaped = pl.class(nnode)
unshaped.type = "unshaped"

--- Constructor
--
-- @tparam table spec A table with the properties of the unshaped node.

function unshaped:_init (spec)
   self:super(spec)
   self.width = nil
end

function unshaped:__tostring ()
   return "U(" .. self:toText() .. ")"
end

getmetatable(unshaped).__index = function (_, _)
   -- if k == "width" then SU.error("Can't get width of unshaped node", true) end
   -- TODO: No idea why porting to proper Penlight classes this ^^^^^^ started
   -- killing everything. Perhaps because this function started working and would
   -- actually need to return rawget(self, k) or something?
end

--- Shapes the text of the unshaped node.
-- This is done by calling the current shaper with the text and options of the node.
-- The result is a list of nnodes inheriting the parent of the unshaped node.
-- The notion of parent is used by the hyphenation logic and discretionaries.
--
-- @treturn table A list of nnodes representing the shaped text.
function unshaped:shape ()
   local node = SILE.shaper:createNnodes(self.text, self.options)
   for i = 1, #node do
      node[i].parent = self.parent
   end
   return node
end

--- Output routine for an unshaped node.
-- Unshaped nodes are not supposed to make it to the output, so this method raises an error.
--
function unshaped.outputYourself (_, _, _)
   SU.error("An unshaped node made it to output", true)
end

--- A discretionary node is a node that can be broken at a certain point.
-- It has optional replacement, prebreak and postbreak nodes, which must be `nnode` nodes.
--
-- Derived from `hbox`.
--
-- Properties is_discretionary is true.
--
-- @type discretionary
-- @usage
-- SILE.types.node.discretionary({ replacement = ..., prebreak =  ..., postbreak = ...})

local discretionary = pl.class(hbox)

discretionary.type = "discretionary"
discretionary.prebreak = {}
discretionary.postbreak = {}
discretionary.replacement = {}
discretionary.used = false

function discretionary:__tostring ()
   return "D("
      .. SU.concat(self.prebreak, "")
      .. "|"
      .. SU.concat(self.postbreak, "")
      .. "|"
      .. SU.concat(self.replacement, "")
      .. ")"
end

--- Returns a text representation of the discretionary node.
-- This is used for debugging purposes, returning '-' for a used discretionary and '_' otherwise.
--
-- @treturn string A string representation of the discretionary node ('-' or '_').
function discretionary:toText ()
   return self.used and "-" or "_"
end

--- Mark the discretionary node as used in prebreak context.
-- This is used to indicate that the discretionary node is used (i.e. the parent is hyphenated)
-- and the prebreak nodes should be output (typically at the end of a broken line).
function discretionary:markAsPrebreak ()
   self.used = true
   if self.parent then
      self.parent.hyphenated = true
   end
   self.is_prebreak = true
end

--- Clone the discretionary node for postbreak use.
-- This is used to create a new discretionary node that is used in postbreak context.
-- The discretionary must previously have been marked as used.
--
-- When breaking compound words, some languages expect the hyphen (prebreak) to be
-- repeated in the postbreak context, typically at the beginning of the next line.
--
-- @treturn SILE.types.node.discretionary A new discretionary node with the same properties as the original, but marked for use in postbreak context.
function discretionary:cloneAsPostbreak ()
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

--- Output routine for a discretionary node.
-- Depending on how the node was marked, it will output either the prebreak, postbreak or replacement nodes.
--
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably ratio)
function discretionary:outputYourself (typesetter, line)
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

--- Returns the width of the prebreak nodes.
--
-- @treturn SILE.types.length The total width of the prebreak nodes.
function discretionary:prebreakWidth ()
   if self.prebw then
      return self.prebw
   end
   self.prebw = SILE.types.length()
   for _, node in ipairs(self.prebreak) do
      self.prebw:___add(node.width)
   end
   return self.prebw
end

--- Returns the width of the postbreak nodes.
--
-- @treturn SILE.types.length The total width of the postbreak nodes.
function discretionary:postbreakWidth ()
   if self.postbw then
      return self.postbw
   end
   self.postbw = SILE.types.length()
   for _, node in ipairs(self.postbreak) do
      self.postbw:___add(node.width)
   end
   return self.postbw
end

--- Returns the width of the replacement nodes.
--
-- @treturn SILE.types.length The total width of the replacement nodes.
function discretionary:replacementWidth ()
   if self.replacew then
      return self.replacew
   end
   self.replacew = SILE.types.length()
   for _, node in ipairs(self.replacement) do
      self.replacew:___add(node.width)
   end
   return self.replacew
end

--- Returns the height of the prebreak nodes.
--
-- @treturn SILE.types.length The total height of the prebreak nodes.
function discretionary:prebreakHeight ()
   if self.prebh then
      return self.prebh
   end
   self.prebh = _maxnode(self.prebreak, "height")
   return self.prebh
end

--- Returns the height of the postbreak nodes.
--
-- @treturn SILE.types.length The total height of the postbreak nodes.
function discretionary:postbreakHeight ()
   if self.postbh then
      return self.postbh
   end
   self.postbh = _maxnode(self.postbreak, "height")
   return self.postbh
end

--- Returns the height of the replacement nodes.
--
-- @treturn SILE.types.length The total height of the replacement nodes.
function discretionary:replacementHeight ()
   if self.replaceh then
      return self.replaceh
   end
   self.replaceh = _maxnode(self.replacement, "height")
   return self.replaceh
end

--- Returns the depth of the prebreak nodes.
--
-- @treturn SILE.types.length The total depth of the prebreak nodes.
function discretionary:replacementDepth ()
   if self.replaced then
      return self.replaced
   end
   self.replaced = _maxnode(self.replacement, "depth")
   return self.replaced
end

--- An alternative node is a node that can be replaced by one of its options.
-- Not for general use:
-- This solution is known to be broken, but it is not clear how to fix it.
--
-- Derived from `hbox`.
--
-- Properties is_alternative and is_box are true.
--
-- @type alternative

local alternative = pl.class(hbox)

alternative.type = "alternative"
alternative.options = {}
alternative.selected = nil

function alternative:__tostring ()
   return "A(" .. SU.concat(self.options, " / ") .. ")"
end

function alternative:minWidth ()
   local minW = function (a, b)
      return SU.min(a.width, b.width)
   end
   return pl.tablex.reduce(minW, self.options)
end

function alternative:deltas ()
   local minWidth = self:minWidth()
   local rv = {}
   for i = 1, #self.options do
      rv[#rv + 1] = self.options[i].width - minWidth
   end
   return rv
end

function alternative:outputYourself (typesetter, line)
   if self.selected then
      self.options[self.selected]:outputYourself(typesetter, line)
   end
end

--- A glue node is a node that can stretch or shrink to fill horizontal space.
--
-- Derived from `box`.
--
-- Properties is_glue is true
--
-- @type glue

local glue = pl.class(box)
glue.type = "glue"
glue.discardable = true

function glue:__tostring ()
   return (self.explicit and "E:" or "") .. "G<" .. tostring(self.width) .. ">"
end

function glue.toText (_)
   return " "
end

--- Output routine for a glue node.
--
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably ratio)
function glue:outputYourself (typesetter, line)
   local outputWidth = SU.rationWidth(self.width:absolute(), self.width:absolute(), line.ratio)
   typesetter.frame:advanceWritingDirection(outputWidth)
end

--- A hfillglue is just a standard glue with infinite stretch.
-- (Convenience subclass so callers do not have to know what infinity is.)
--
-- Derived from `glue`.
--
-- @type hfillglue

local hfillglue = pl.class(glue)

--- Constructor
--
-- @tparam table spec A table with the properties of the glue.
function hfillglue:_init (spec)
   self:super(spec)
   self.width = SILE.types.length(self.width.length, infinity, self.width.shrink)
end

--- A hssglue is just a standard glue with infinite stretch and shrink.
-- (Convenience subclass so callers do not have to know what infinity is.)
--
-- Derived from `glue`.
--
-- @type hssglue

local hssglue = pl.class(glue)

--- Constructor
--
-- @tparam table spec A table with the properties of the glue.
function hssglue:_init (spec)
   self:super(spec)
   self.width = SILE.types.length(self.width.length, infinity, infinity)
end

--- A kern node is a node that can stretch or shrink to fill horizontal space,
-- It represents a non-breakable space (for the purpose of line breaking).
--
-- Derived from `glue`.
--
-- Property is_kern is true.
--
-- @type kern
local kern = pl.class(glue)
kern.type = "kern" -- Perhaps some smell here, see comment on vkern
kern.discardable = false

function kern:__tostring ()
   return "K<" .. tostring(self.width) .. ">"
end

--- A vglue node is a node that can stretch or shrink to fill vertical space.
--
-- Derived from `box`.
--
-- Property is_vglue is true.
--
-- @type vglue

local vglue = pl.class(box)
vglue.type = "vglue"
vglue.discardable = true
vglue._default_length = "height"
vglue.adjustment = nil

--- Constructor
--
-- @tparam table spec A table with the properties of the vglue.
function vglue:_init (spec)
   self.adjustment = SILE.types.measurement()
   self:super(spec)
end

function vglue:__tostring ()
   return (self.explicit and "E:" or "") .. "VG<" .. tostring(self.height) .. ">"
end

--- Adjust the vglue by a certain amount.
--
-- @tparam SILE.types.length adjustment The amount to adjust the vglue by.
function vglue:adjustGlue (adjustment)
   self.adjustment = adjustment
end

--- Output routine for a vglue.
--
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably height and depth)
function vglue:outputYourself (typesetter, line)
   typesetter.frame:advancePageDirection(line.height:absolute() + line.depth:absolute() + self.adjustment)
end

function vglue:unbox ()
   return { self }
end

--- A vfillglue is just a standard vglue with infinite stretch.
-- (Convenience subclass so callers do not have to know what infinity is.)
--
-- Derived from `vglue`.
-- @type vfillglue

local vfillglue = pl.class(vglue)

function vfillglue:_init (spec)
   self:super(spec)
   self.height = SILE.types.length(self.width.length, infinity, self.width.shrink)
end

--- A vssglue is a just standard vglue with infinite stretch and shrink.
-- (Convenience subclass so callers do not have to know what infinity is.)
--
-- Derived from `vglue`
--
-- @type vssglue
local vssglue = pl.class(vglue)
function vssglue:_init (spec)
   self:super(spec)
   self.height = SILE.types.length(self.width.length, infinity, infinity)
end

--- A zerovglue is a standard vglue with zero height and depth.
-- (Convenience subclass)
--
-- Derived from `vglue`.
--
-- @type zerovglue

local zerovglue = pl.class(vglue)

--- A vkern node is a node that can stretch or shrink to fill vertical space,
-- It represents a non-breakable space (for the purpose of page breaking).
--
-- Derived from `vglue`.
--
-- @type vkern
local vkern = pl.class(vglue)
-- FIXME TODO
-- Here we cannot do:
--   vkern.type = "vkern"
-- It cannot be typed as "vkern" as the pagebuilder doesn't check is_vkern.
-- So it's just a vglue currrenty, marked as not discardable...
-- But on the other hand, kern is typed "kern" and is not a glue...
-- Frankly, the discardable/explicit flags and the types are too
-- entangled and point towards a more general design issue.
-- N.B. this vkern node is only used in the linespacing package so far.
vkern.discardable = false

function vkern:__tostring ()
   return "VK<" .. tostring(self.height) .. ">"
end

--- A penalty node has a value which is used by the line breaking algorithm (in horizontal mode)
-- or the page breaking algorithm (in vertical mode), to determine where to break.
-- The value is expected to be a number between -10000 and 10000.
-- The higher the value, the less desirable it is to break at that point.
-- The extreme values (-10000 and 10000) are used to indicate that the break is forbidden or mandatory,
-- i.e. in certain way represent an infinite penalty.
--
-- Derived from `box`.
--
-- Property is_penalty is true.
--
-- @type penalty

local penalty = pl.class(box)
penalty.type = "penalty"
penalty.discardable = true
penalty.penalty = 0

--- Constructor
-- @tparam table spec A table with the properties of the penalty.
function penalty:_init (spec)
   self:super(spec)
   if type(spec) ~= "table" then
      self.penalty = SU.cast("number", spec)
   end
end

function penalty:__tostring ()
   return "P(" .. tostring(self.penalty) .. ")"
end

--- Output routine for a penalty.
-- If found in the output, penalties have no representation, so this method does nothing.
-- (Overriding it on some penalties may be useful for debugging purposes.)
--
function penalty.outputYourself (_, _, _) end

--- Returns a text representation of the penalty node.
-- This is used for debugging purposes, returning '(!)' for a penalty.
--
-- @treturn string A string representation of the penalty node ('(!)').
function penalty.toText (_)
   return "(!)"
end

--- Unbox a penalty.
-- This method exists consistency with vbox-derived classes, for a penalty used in vertical mode.
--
-- @treturn table A table with the penalty node.
function penalty:unbox ()
   return { self }
end

--- A vbox is a box node used in vertical mode.
--
-- Derived from `box`.
--
-- Properties is_vbox and is_box are true.
--
-- @type vbox

local vbox = pl.class(box)
vbox.type = "vbox"
vbox.nodes = {}
vbox._default_length = "height"

--- Constructor
--
-- @tparam table spec A table with the properties of the vbox.
function vbox:_init (spec)
   self.nodes = {}
   self:super(spec)
   self.depth = _maxnode(self.nodes, "depth")
   self.height = _maxnode(self.nodes, "height")
end

function vbox:__tostring ()
   return "VB<" .. tostring(self.height) .. "|" .. self:toText() .. "v" .. tostring(self.depth) .. ")"
end

--- Returns a text representation of the vbox.
-- This is used for debugging purposes, returning a string representation of the vbox and its content.
--
-- @treturn string A string representation of the vbox.
function vbox:toText ()
   return "VB["
      .. SU.concat(
         SU.map(function (node)
            return node:toText()
         end, self.nodes),
         ""
      )
      .. "]"
end

--- Output routine for a vbox.
--
-- @tparam SILE.typesetters.base typesetter The typesetter object (only used for the frame).
-- @tparam table line Line properties (notably ratio)
function vbox:outputYourself (typesetter, line)
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

--- Unbox a vbox.
--
-- @treturn table A table with the nodes inside the vbox.
function vbox:unbox ()
   for i = 1, #self.nodes do
      if self.nodes[i].is_vbox or self.nodes[i].is_vglue then
         return self.nodes
      end
   end
   return { self }
end

--- Added a box or several to the current vbox.
-- The box height is the height is the total height of the content, minus the depth of the last box.
-- The depth of the vbox is the depth of the last box.
--
-- @tparam box|table box A box or a list of boxes to add to the vbox.
function vbox:append (node)
   if not node then
      SU.error("nil box given", true)
   end
   local nodes = node.type and node:unbox() or node
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

--- A migrating node is a node that can be moved from one frame to another.
-- Typically, footnotes are migrating nodes.
--
-- Derived from `hbox`.
--
-- Properties ìs_migrating, is_hbox and is_box are true.
--
-- @type migrating
-- @usage
-- SILE.types.node.migrating({ material =  ... })
--

local migrating = pl.class(hbox)
migrating.type = "migrating"
migrating.material = {}
migrating.value = {}
migrating.nodes = {}

function migrating:__tostring ()
   return "<M: " .. tostring(self.material) .. ">"
end

-- DEPRECATED FUNCTIONS

local function _deprecated_isX ()
   SU.deprecated("node:isX()", "is_X", "0.10.0", "0.16.0")
end

box.isBox = _deprecated_isX
box.isNnode = _deprecated_isX
box.isGlue = _deprecated_isX
box.isVglue = _deprecated_isX
box.isZero = _deprecated_isX
box.isUnshaped = _deprecated_isX
box.isAlternative = _deprecated_isX
box.isVbox = _deprecated_isX
box.isInsertion = _deprecated_isX
box.isMigrating = _deprecated_isX
box.isPenalty = _deprecated_isX
box.isDiscretionary = _deprecated_isX
box.isKern = _deprecated_isX

local _deprecated_nodefactory = {
   newHbox = true,
   newNnode = true,
   newUnshaped = true,
   newDisc = true,
   disc = true,
   newAlternative = true,
   newGlue = true,
   newKern = true,
   newVglue = true,
   newVKern = true,
   newPenalty = true,
   newDiscretionary = true,
   newVbox = true,
   newMigrating = true,
   zeroGlue = true,
   hfillGlue = true,
   vfillGlue = true,
   hssGlue = true,
   vssGlue = true,
   zeroHbox = true,
   zeroVglue = true,
}

-- EXPORTS WRAP-UP

local nodetypes = {
   box = box,
   hbox = hbox,
   zerohbox = zerohbox,
   nnode = nnode,
   unshaped = unshaped,
   discretionary = discretionary,
   alternative = alternative,
   glue = glue,
   hfillglue = hfillglue,
   hssglue = hssglue,
   kern = kern,
   vglue = vglue,
   vfillglue = vfillglue,
   vssglue = vssglue,
   zerovglue = zerovglue,
   vkern = vkern,
   penalty = penalty,
   vbox = vbox,
   migrating = migrating,
}

setmetatable(nodetypes, {
   __index = function (_, prop)
      if _deprecated_nodefactory[prop] then
         SU.deprecated(
            "SILE.types.node." .. prop,
            "SILE.types.node." .. prop:match("n?e?w?(.*)"):lower(),
            "0.10.0",
            "0.14.0"
         )
      elseif type(prop) == "number" then -- luacheck: ignore 542
      -- Likely an attempt to iterate, inspect, or dump the table, sort of safe to ignore
      else
         SU.error("Attempt to access non-existent SILE.types.node." .. prop)
      end
   end,
})

return nodetypes

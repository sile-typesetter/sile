--- core frame registry instance
--- @module SILE.frames

--- @type frames
local registry = require("types.registry")
local frames = pl.class(registry)
frames._name = "frames"

frames.sets = {}
frames.current = {}

function frames:_init ()
   registry._init(self)
   self.default = nil
end

function frames:new (parent, spec, prototype)
   if self:exists(parent, spec.id) then
      SU.debug("frames", "WARNING: Redefining frame", spec.id)
   else
      SU.debug("frames", "Defining frame", spec.id)
      self._registry[spec.id] = {}
   end
   prototype = prototype or SILE.types.frame
   local frame = prototype(spec)
   -- If we only have one frame, make it the default
   if not self.default or spec.default then
      self.default = frame
   end
   return self:push(parent, frame)
end

-- Wrap registry:pull(), but handle return current fragment of split frames
function frames:pull (parent, id)
   id = id or self.default
   local frame, last_attempt
   while not frame do
      if self:exists(parent, id) then
         frame = registry.pull(self, parent, id)
      else
         id = id:gsub("_$", "")
         if id == last_attempt then
            break
         end
         last_attempt = id
      end
   end
   return frame or SU.error("Couldn't find frame ID " .. id, true)
end

function frames:setDefault (_parent, id)
   self.default = id
end

function frames:getDefault (parent)
   return self:pull(parent, self.default)
end

function frames:getNext (parent)
   if parent.type ~= "typesetter" then
      SU.warn("Implement finding current frame outside of the typesetter")
      parent = SILE.typesetter
   end
   local current = parent.frame
   local next = current.next
   return next and self:pull(next)
end

function frames:use (parent, frame)
   if parent.type ~= "typesetter" then
      SU.error("Attempt by non-typesetter to use a frame")
   end
   if type(frame) == "string" then
      SU.deprecated("frames:use", "frames:use", "0.16.0", "0.17.0", [[Wants frame, not id]])
      frame = self:pull(parent, frame)
   end
   self.current = frame
   frame:connectToTypesetter(parent)
end

-- Keep a copy of clean frames around for use in the next page
function frames:defineSet (parent, set_id)
   SU.debug("frames", "Turning all registered frames into set")
   local set = {}
   for frame_id, frame in self:iterate(parent) do
      set[frame_id] = frame:clone()
   end
   table.insert(self.sets, set)
   if set_id then
      self.sets[set_id] = #self.sets
   end
   return set_id or #self.sets
end

function frames:enterSet (parent, id)
   if #self.sets == 0 then
      SU.debug("frames", "No sets detected, making current frames into a set")
      self:defineSet(parent)
   end
   id = id or #self.sets
   local set = self.sets[id]
   self:clear()
   -- Bring in the frame set as the current set of frames in the stack
   for _, frame in pairs(set) do
      self:push(parent, frame)
   end
   -- Find the first content frame
   local frame = self:getDefault(parent)
   SU.debug("frames", "Entering set", id, "into first content frame", frame)
   frame:solve()
   return frame
end

local cassowary = require("cassowary")
local solver = cassowary.SimplexSolver()

function frames:parseComplexFrameDimension (_parent, dimension)
   local length = SILE.frameParser:match(SU.cast("string", dimension))
   if type(length) == "table" then
      local g = cassowary.Variable({ name = "t" })
      local eq = cassowary.Equation(g, length)
      local page = self:pull("page")
      page:invalidate()
      solver:addConstraint(eq)
      page:solve()
      page:invalidate()
      return g.value
   end
   return length
end

function frames:_post_init ()
   local mt = getmetatable(self)
   function mt.__index (_, id)
      SU.deprecated("SILE.frames[]", "<module>.frames:pull", "0.16.0", "0.17.0")
      return self:pull(id)
   end
   function mt.__newindex (_name, spec)
      SU.deprecated("SILE.frames[]", "<module>.frames:new", "0.16.0", "0.17.0")
      return self:new(spec)
   end
end

function frames:dump ()
   for _, frame in self:iterate() do
      SU.debug("frames", frame:__debug())
   end
end

return frames

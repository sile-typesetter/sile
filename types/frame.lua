-- Buggy, relies on side effects
-- luacheck: ignore solver frame
-- See https://github.com/sile-typesetter/sile/issues/694

local cassowary = require("cassowary")
local solver = cassowary.SimplexSolver()

local frame = pl.class()
frame.type = "frame"

local solverNeedsReloading = true

local widthdims = pl.Set({ "left", "right", "width" })
local heightdims = pl.Set({ "top", "bottom", "height" })
local alldims = widthdims + heightdims

frame.direction = "LTR-TTB"

-- TODO refactor with a hook table with multiple types
frame.enterHooks = {}
frame.leaveHooks = {}

function frame:_init (spec, dummy)
   SU.required(spec, "id", "frame declaration")
   self._spec = spec
   -- Redo this to read form the typesetter status on enter, not on frame creation
   local direction = SILE.documentState.direction
   if direction then
      self.direction = direction
   end
   self.id = spec.id
   self.balanced = SU.boolean(spec.balanced, false)
   self.mirrored = SU.boolean(spec.mirrored, false) -- TODO redo twoside, use this to swap constraints
   self.flipped = SU.boolean(spec.flipped, false) -- TODO implement the same as mirroring for vertical
   self.dummy = SU.boolean(dummy or spec.dummy, false)
   for k, v in pairs(spec) do
      if not alldims[k] then
         self[k] = v
      end
   end
   self._constraints = {}
   self._variables = {}
   for method in pairs(alldims) do
      self[method] = function ()
         SU.error("Attempt to use a size method from an unresolved frame", true)
      end
   end
end

function frame:_post_init ()
   self.constraints = setmetatable({}, {
      __index = function (_, key)
         SU.deprecated(
            "frame.constraints.*",
            "frame._constraints",
            "0.16.0",
            "0.17.0",
            [[Use the contsraint method to fetch constraints.]]
         )
         return self._constraints[key]
      end,
      __newindex = function (_, key, value)
         SU.deprecated(
            "frame.constraints.*",
            "frame:constrain()",
            "0.16.0",
            "0.17.0",
            [[Use the constrain method to add constraints.]]
         )
         return self:constrain(key, value)
      end,
   })
   if not self.dummy then
      for method in pairs(alldims) do
         self._variables[method] = cassowary.Variable({ name = self._spec.id .. "_" .. method })
         self[method] = function (self_)
            self_:solve()
            local value = self_._variables[method].value
            return SILE.types.measurement(value)
         end
      end
      -- Add definitions of width and height
      for method in pairs(alldims) do
         if self._spec[method] then
            self:constrain(method, self._spec[method])
         end
      end
   end
end

function frame:init (typesetter)
   SU.deprecated("frame:init", "frame:connectToTypesetter", "0.16.0", "0.17.0")
   return self:connectToTypesetter(typesetter)
end

-- This gets called by us in typesetter before we start to use the frame
function frame:connectToTypesetter (typesetter)
   -- TODO make sure is solved
   if self.typesetter then
      SU.warn("Re-using frame that has already been connected to a typesetter")
   end
   self.state = { totals = { height = SILE.types.measurement(0) } }
   self:enter(typesetter)
   self:resetCursor()
   self:newLine(typesetter)
   self.typesetter = typesetter
   return self
end

function frame:resetCursor ()
   if self:pageAdvanceDirection() == "TTB" then
      self.state.cursorY = self:top()
   elseif self:pageAdvanceDirection() == "LTR" then
      self.state.cursorX = self:left()
   elseif self:pageAdvanceDirection() == "RTL" then
      self.state.cursorX = self:right()
   elseif self:pageAdvanceDirection() == "BTT" then
      self.state.cursorY = self:bottom()
   end
end

function frame:constrain (method, dimension)
   self._constraints[method] = tostring(dimension)
   self:invalidate()
end

function frame:constraint (method)
   return tostring(self._constraints[method])
end

function frame:iterateConstraints ()
   SU.debug("frames", "Iterating constraints for", self.id)
   return pairs(self._constraints)
end

function frame:invalidate ()
   solverNeedsReloading = true
end

function frame:relax (method)
   self._constraints[method] = nil
   self:invalidate()
end

function frame:reifyConstraint (solver, method, stay)
   local constraint = self._constraints[method]
   if not constraint then
      return
   end
   constraint = SU.type(constraint) == "measurement" and constraint:tonumber() or SILE.frameParser:match(constraint)
   SU.debug("frames", function ()
      return "Adding constraint " .. method .. " to " .. self.id .. " as " .. tostring(constraint)
   end)
   local eq = cassowary.Equation(self._variables[method], constraint)
   solver:addConstraint(eq)
   if stay then
      solver:addStay(eq)
   end
end

function frame:addWidthHeightDefinitions (solver)
   local vars = self._variables
   solver:addConstraint(cassowary.Equation(vars.width, cassowary.minus(vars.right, vars.left)))
   solver:addConstraint(cassowary.Equation(vars.height, cassowary.minus(vars.bottom, vars.top)))
end

-- This is hideously inefficient,
-- but it's the easiest way to allow users to reconfigure frames at runtime.
function frame:solve ()
   if not solverNeedsReloading then
      return
   end
   SU.debug("frames", "Begin solving...")
   solver = cassowary.SimplexSolver()
   if SILE.frames:exists("page") then
      local page = SILE.frames:pull("page")
      for method, _ in page:iterateConstraints() do
         page:reifyConstraint(solver, method, true)
      end
      page:addWidthHeightDefinitions(solver)
   end
   for id, frame in SILE.frames:iterate() do
      SU.debug("frame", "Solving", id)
      if id ~= "page" then
         for method, _ in frame:iterateConstraints() do
            frame:reifyConstraint(solver, method)
         end
         frame:addWidthHeightDefinitions(solver)
      end
   end
   solver:solve()
   solverNeedsReloading = false
end

function frame:writingDirection ()
   return self.direction:match("^(%a+)") or "LTR"
end

function frame:pageAdvanceDirection ()
   return self.direction:match("-(%a+)$") or "TTB"
end

function frame:advanceWritingDirection (length)
   local amount = SU.cast("number", length)
   if amount == 0 then
      return
   end
   if self:writingDirection() == "RTL" then
      self.state.cursorX = self.state.cursorX - amount
   elseif self:writingDirection() == "LTR" then
      self.state.cursorX = self.state.cursorX + amount
   elseif self:writingDirection() == "TTB" then
      self.state.cursorY = self.state.cursorY + amount
   elseif self:writingDirection() == "BTT" then
      self.state.cursorY = self.state.cursorY - amount
   end
end

function frame:advancePageDirection (length)
   local amount = SU.cast("number", length)
   if amount == 0 then
      return
   end
   if self:pageAdvanceDirection() == "TTB" then
      self.state.cursorY = self.state.cursorY + amount
   elseif self:pageAdvanceDirection() == "RTL" then
      self.state.cursorX = self.state.cursorX - amount
   elseif self:pageAdvanceDirection() == "LTR" then
      self.state.cursorX = self.state.cursorX + amount
   elseif self:pageAdvanceDirection() == "BTT" then
      self.state.cursorY = self.state.cursorY - amount
   end
end

function frame:newLine ()
   if self:writingDirection() == "LTR" then
      self.state.cursorX = self:left()
   elseif self:writingDirection() == "RTL" then
      self.state.cursorX = self:right()
   elseif self:writingDirection() == "TTB" then
      self.state.cursorY = self:top()
   elseif self:writingDirection() == "BTT" then
      self.state.cursorY = self:bottom()
   end
end

function frame:lineWidth ()
   SU.deprecated("frame:lineWidth()", "frame:getLineWidth()", "0.10.0", "0.16.0")
end

function frame:getLineWidth ()
   if self:writingDirection() == "LTR" or self:writingDirection() == "RTL" then
      return self:width()
   else
      return self:height()
   end
end

function frame:pageTarget ()
   SU.warn("Method :pageTarget() is deprecated, please use :getTargetLength()")
   return self:getTargetLength()
end

function frame:getTargetLength ()
   local direction = self:pageAdvanceDirection()
   if direction == "TTB" or direction == "BTT" then
      return self:height()
   else
      return self:width()
   end
end

function frame:enter (typesetter)
   -- TODO make sure is solved
   for i = 1, #self.enterHooks do
      self.enterHooks[i](self, typesetter)
   end
end

function frame:leave (typesetter)
   for i = 1, #self.leaveHooks do
      self.leaveHooks[i](self, typesetter)
   end
end

function frame:isAbsoluteConstraint (method)
   if not self.constraints[method] then
      return false
   end
   local constraint = SILE.frameParser:match(self.constraints[method])
   if type(constraint) ~= "table" then
      return true
   end
   if not constraint.terms then
      return false
   end
   for clv, _ in pairs(constraint.terms) do
      if clv.name and not clv.name:match("^page_") then
         return false
      end
   end
   return true
end

function frame:isMainContentFrame ()
   local frame = self.typesetter.frames:getDefault()
   while frame do
      if frame == self then
         return true
      end
      if frame.next then
         frame = frame:getNext()
      else
         return false
      end
   end
   return false
end

-- Return a fresh copy of the frame based on the original specs without being "in use" by a typesetter or having any of
-- the constraints solved.
function frame:clone ()
   local spec = pl.tablex.copy(self._spec)
   local frame = self._class(spec)
   for _, k in ipairs({ "balanced", "mirrored", "flipped", "dummy", "direction", "enterHooks", "leaveHooks" }) do
      frame[k] = self[k]
   end
   return frame
end

function frame:__tostring ()
   return self.id
end

function frame:__debug ()
   local str = "<Frame: " .. self.id .. ": "
   str = str .. " next=" .. (self.next or "nil") .. " "
   if not solverNeedsReloading then
      for method, dimension in self:iterateConstraints() do
         str = str .. method .. "=" .. dimension .. "; "
      end
   else
      str = str .. "unsolved"
   end
   if self.hanmen then
      str = str .. "tate=" .. (self.tate and "true" or "false") .. "; "
      str = str .. "gridsize=" .. self.gridsize .. "; "
      str = str .. "linegap=" .. self.linegap .. "; "
      str = str .. "linelength=" .. self.linelength .. "; "
      str = str .. "linecount=" .. self.linecount .. "; "
   end
   str = str .. ">"
   return str
end

-- Work around _post_init() only getting called from base classes
local _frame = pl.class(frame)
return _frame

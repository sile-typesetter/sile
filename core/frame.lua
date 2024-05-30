SILE.frames = {}

-- Buggy, relies on side effects
-- luacheck: ignore solver frame
-- See https://github.com/sile-typesetter/sile/issues/694

local cassowary = require("cassowary")
local solver = cassowary.SimplexSolver()
local solverNeedsReloading = true

local widthdims = pl.Set({ "left", "right", "width" })
local heightdims = pl.Set({ "top", "bottom", "height" })
local alldims = widthdims + heightdims

SILE.framePrototype = pl.class({
   direction = "LTR-TTB",
   enterHooks = {},
   leaveHooks = {},

   -- This gets called by Penlght when creating the frame instance
   _init = function (self, spec, dummy)
      local direction = SILE.documentState.direction
      if direction then
         self.direction = direction
      end
      self.constraints = {}
      self.variables = {}
      self.id = spec.id
      for k, v in pairs(spec) do
         if not alldims[k] then
            self[k] = v
         end
      end
      self.balanced = SU.boolean(self.balanced, false)
      if not dummy then
         for method in pairs(alldims) do
            self.variables[method] = cassowary.Variable({ name = spec.id .. "_" .. method })
            self[method] = function (instance_self)
               instance_self:solve()
               return SILE.measurement(instance_self.variables[method].value)
            end
         end
         -- Add definitions of width and height
         for method in pairs(alldims) do
            if spec[method] then
               self:constrain(method, spec[method])
            end
         end
      end
   end,

   -- This gets called by us in typesetter before we start to use the frame
   init = function (self, typesetter)
      self.state = { totals = { height = SILE.measurement(0) } }
      self:enter(typesetter)
      self:newLine(typesetter)
      if self:pageAdvanceDirection() == "TTB" then
         self.state.cursorY = self:top()
      elseif self:pageAdvanceDirection() == "LTR" then
         self.state.cursorX = self:left()
      elseif self:pageAdvanceDirection() == "RTL" then
         self.state.cursorX = self:right()
      elseif self:pageAdvanceDirection() == "BTT" then
         self.state.cursorY = self:bottom()
      end
   end,

   constrain = function (self, method, dimension)
      self.constraints[method] = tostring(dimension)
      self:invalidate()
   end,

   invalidate = function ()
      solverNeedsReloading = true
   end,

   relax = function (self, method)
      self.constraints[method] = nil
   end,

   reifyConstraint = function (self, solver, method, stay)
      local constraint = self.constraints[method]
      if not constraint then
         return
      end
      constraint = SU.type(constraint) == "measurement" and constraint:tonumber() or SILE.frameParser:match(constraint)
      SU.debug("frames", "Adding constraint", self.id, function ()
         return "(" .. method .. ") = " .. tostring(constraint)
      end)
      local eq = cassowary.Equation(self.variables[method], constraint)
      solver:addConstraint(eq)
      if stay then
         solver:addStay(eq)
      end
   end,

   addWidthHeightDefinitions = function (self, solver)
      local vars = self.variables
      solver:addConstraint(cassowary.Equation(vars.width, cassowary.minus(vars.right, vars.left)))
      solver:addConstraint(cassowary.Equation(vars.height, cassowary.minus(vars.bottom, vars.top)))
   end,

   -- This is hideously inefficient,
   -- but it's the easiest way to allow users to reconfigure frames at runtime.
   solve = function (_)
      if not solverNeedsReloading then
         return
      end
      SU.debug("frames", "Solving...")
      solver = cassowary.SimplexSolver()
      if SILE.frames.page then
         for method, _ in pairs(SILE.frames.page.constraints) do
            SILE.frames.page:reifyConstraint(solver, method, true)
         end
         SILE.frames.page:addWidthHeightDefinitions(solver)
      end
      for id, frame in pairs(SILE.frames) do
         if not (id == "page") then
            for method, _ in pairs(frame.constraints) do
               frame:reifyConstraint(solver, method)
            end
            frame:addWidthHeightDefinitions(solver)
         end
      end
      solver:solve()
      solverNeedsReloading = false
   end,

   writingDirection = function (self)
      return self.direction:match("^(%a+)") or "LTR"
   end,

   pageAdvanceDirection = function (self)
      return self.direction:match("-(%a+)$") or "TTB"
   end,

   advanceWritingDirection = function (self, length)
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
   end,

   advancePageDirection = function (self, length)
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
   end,

   newLine = function (self, _)
      if self:writingDirection() == "LTR" then
         self.state.cursorX = self:left()
      elseif self:writingDirection() == "RTL" then
         self.state.cursorX = self:right()
      elseif self:writingDirection() == "TTB" then
         self.state.cursorY = self:top()
      elseif self:writingDirection() == "BTT" then
         self.state.cursorY = self:bottom()
      end
   end,

   lineWidth = function (self)
      SU.warn("Method :lineWidth() is deprecated, please use :getLineWidth()")
      return self:getLineWidth()
   end,

   getLineWidth = function (self)
      if self:writingDirection() == "LTR" or self:writingDirection() == "RTL" then
         return self:width()
      else
         return self:height()
      end
   end,

   pageTarget = function (self)
      SU.warn("Method :pageTarget() is deprecated, please use :getTargetLength()")
      return self:getTargetLength()
   end,

   getTargetLength = function (self)
      local direction = self:pageAdvanceDirection()
      if direction == "TTB" or direction == "BTT" then
         return self:height()
      else
         return self:width()
      end
   end,

   enter = function (self, typesetter)
      for i = 1, #self.enterHooks do
         self.enterHooks[i](self, typesetter)
      end
   end,

   leave = function (self, typesetter)
      for i = 1, #self.leaveHooks do
         self.leaveHooks[i](self, typesetter)
      end
   end,

   isAbsoluteConstraint = function (self, method)
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
   end,

   isMainContentFrame = function (self)
      local tpt = SILE.documentState.thisPageTemplate
      local frame = tpt.firstContentFrame
      while frame do
         if frame == self then
            return true
         end
         if frame.next then
            frame = SILE.getFrame(frame.next)
         else
            return false
         end
      end
      return false
   end,

   __tostring = function (self)
      local str = "<Frame: " .. self.id .. ": "
      str = str .. " next=" .. (self.next or "nil") .. " "
      for method, dimension in pairs(self.constraints) do
         str = str .. method .. "=" .. dimension .. "; "
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
   end,
})

SILE.newFrame = function (spec, prototype)
   SU.required(spec, "id", "frame declaration")
   prototype = prototype or SILE.framePrototype
   local frame = prototype(spec)
   SILE.frames[spec.id] = frame
   return frame
end

SILE.getFrame = function (id)
   if type(id) == "table" then
      SU.error("Passed a table, expected a string", true)
   end
   local frame, last_attempt
   while not frame do
      frame = SILE.frames[id]
      id = id:gsub("_$", "")
      if id == last_attempt then
         break
      end
      last_attempt = id
   end
   return frame or SU.warn("Couldn't find frame ID " .. id, true)
end

SILE.parseComplexFrameDimension = function (dimension)
   local length = SILE.frameParser:match(SU.cast("string", dimension))
   if type(length) == "table" then
      local g = cassowary.Variable({ name = "t" })
      local eq = cassowary.Equation(g, length)
      solverNeedsReloading = true
      solver:addConstraint(eq)
      SILE.frames.page:solve()
      solverNeedsReloading = true
      return g.value
   end
   return length
end

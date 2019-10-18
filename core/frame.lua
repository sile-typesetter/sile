SILE.frames = {}

local cassowary = require("cassowary")
local solver = cassowary.SimplexSolver()
local solverNeedsReloading = true

local alldims = { top="h", bottom="h", height="h", left="w", right="w", width="w"}

SILE.framePrototype = pl.class({
    direction = "LTR-TTB",
    enterHooks = {},
    leaveHooks = {},

    -- This gets called by Penlght when creating the frame instance
    _init = function (self, spec, dummy)
      self.constraints = {}
      self.variables = {}
      self.id = spec.id
      for k, v in pairs(spec) do
        if not alldims[k] then self[k] = v end
      end
      self.balanced = SU.boolean(self.balanced, false)
      if not dummy then
        for method, _ in pairs(alldims) do
          self.variables[method] = cassowary.Variable({ name = spec.id .. "_" .. method })
          self[method] = function (self)
            self:solve()
            return self.variables[method].value
          end
        end
        -- Add definitions of width and height
        for method, _ in pairs(alldims) do
          if spec[method] then
            self:constrain(method, spec[method])
          end
        end
      end
    end,

    -- This gets called by us in typesetter before we start to use the frame
    init = function (self)
      self.state = { totals = { height= 0, pastTop = false } }
      self:enter()
      self:newLine()
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
      self.constraints[method] = dimension
      self:invalidate()
    end,

    invalidate = function ()
      solverNeedsReloading = true
    end,

    relax = function (self, method)
      self.constraints[method] = nil
    end,

    reifyConstraint = function (self, solver, method, stay)
      if not self.constraints[method] then return end
      local constraint = SILE.frameParser:match(self.constraints[method])
      SU.debug("frames", "Adding constraint "..self.id.."("..method..") = "..constraint)
      local eq = cassowary.Equation(self.variables[method], constraint)
      solver:addConstraint(eq)
      if stay then solver:addStay(eq) end
    end,

    addWidthHeightDefinitions = function (self, solver)
      solver:addConstraint(cassowary.Equation(self.variables.width, cassowary.minus(self.variables.right, self.variables.left)))
      solver:addConstraint(cassowary.Equation(self.variables.height, cassowary.minus(self.variables.bottom, self.variables.top)))
    end,

    -- This is hideously inefficient,
    -- but it's the easiest way to allow users to reconfigure frames at runtime.
    solve = function (_)
      if not solverNeedsReloading then return end
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

    writingDirection     = function (self) return self.direction:match("^(%a+)") or "LTR" end,
    pageAdvanceDirection = function (self) return self.direction:match("-(%a+)$") or "TTB" end,

    advanceWritingDirection = function (self, amount)
      if type(amount) == "table" then
        if (amount.prototype and amount:prototype() == "RelativeMeasurement")
          or (amount.type and amount.type == "RelativeMeasurement") then
          amount = amount:absolute()
        else
          SU.error("Table passed to advanceWritingDirection", true)
        end
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

    advancePageDirection = function (self, amount)
      if type(amount) == "table" then
        if (amount.prototype and amount:prototype() == "RelativeMeasurement")
          or (amount.type and amount.type == "RelativeMeasurement") then
          amount = amount:absolute()
        else
        SU.error("Table passed to advancePageDirection", true) end
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

    newLine = function(self)
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
      if self:writingDirection() == "LTR" or self:writingDirection() == "RTL" then
        return self:width()
      else
        return self:height()
      end
    end,

    pageTarget = function (self)
      if self:pageAdvanceDirection() == "TTB" or self:pageAdvanceDirection() == "BTT" then
        return self:height()
      else
        return self:width()
      end
    end,

    enter = function (self)
      for i = 1, #self.enterHooks do
        self.enterHooks[i](self)
      end
    end,

    leave = function (self)
      for i = 1, #self.leaveHooks do
        self.leaveHooks[i](self)
      end
    end,

    isAbsoluteConstraint = function (self, method)
      if not self.constraints[method] then return false end
      local constraint = SILE.frameParser:match(self.constraints[method])
      if type(constraint) ~= "table" then return true end
      if not constraint.terms then return false end
      for clv, _ in pairs(constraint.terms) do
        if clv.name and not clv.name:match("^page_") then
          return false
        end
      end
      return true
    end,

    isMainContentFrame = function (self)
      local frame =  SILE.documentState.thisPageTemplate.firstContentFrame
      while frame do
        if frame == self then return true end
        if frame.next then frame = SILE.getFrame(frame.next) else return false end
      end
      return false
    end,

    __tostring = function(self)
      local str = "<Frame: " .. self.id .. ": "
      str = str .. " next=" .. self.next .. " "
      for method, dimension in pairs(self.constraints) do
        str = str .. method .. "=" .. dimension .. "; "
      end
      str = str .. ">"
      return str
    end
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
  return SILE.frames[id] or SU.warn("Couldn't find frame ID "..id, true)
end

SILE.parseComplexFrameDimension = function (dimension)
  local length = SILE.frameParser:match(dimension)
  length = SILE.toAbsoluteMeasurement(length)
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

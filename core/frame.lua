local cassowary = require("cassowary")
SILE.frames = {}
local solver = cassowary.SimplexSolver()
solverNeedsReloading = true

SILE._frameParser = require("core/frameparser")

local parseFrameDef = function(dimension)
  return SILE._frameParser:match(dimension)
end

local dims = { top="h", bottom="h", height="h", left="w", right="w", width="w"}

SILE.framePrototype = std.object {
  next= nil,
  id= nil,
  previous= nil,
  balanced= false,
  direction = "LTR-TTB",
  writingDirection     = function (self) return self.direction:match("^(%a+)") end,
  pageAdvanceDirection = function (self) return self.direction:match("-(%a+)$") or "TTB" end,
  state = {},
  enterHooks = {},
  leaveHooks = {},
  constrain = function (self, method, dimension)
    self.constraints[method] = dimension
    self:invalidate()
  end,
  invalidate = function()
    solverNeedsReloading = true
  end,
  relax = function(self, method)
    self.constraints[method] = nil
  end,
  reifyConstraint = function(self, solver, method, stay)
    if not self.constraints[method] then return end
    local constraint = parseFrameDef(self.constraints[method])
    -- print("Adding constraint "..self.id.."("..method..") = "..constraint)
    local eq = cassowary.Equation(self.variables[method], constraint)
    solver:addConstraint(eq)
    if stay then solver:addStay(eq) end
  end,
  addWidthHeightDefinitions = function(self, solver)
    solver:addConstraint(cassowary.Equation(self.variables.width, cassowary.minus(self.variables.right, self.variables.left)))
    solver:addConstraint(cassowary.Equation(self.variables.height, cassowary.minus(self.variables.bottom, self.variables.top)))
  end,
  -- This is hideously inefficient,
  -- but it's the easiest way to allow users to reconfigure frames at runtime.
  solve = function(self)
    if not solverNeedsReloading then return end
    --print("Solving")
    solver = cassowary.SimplexSolver()
    if SILE.frames.page then
      for method, dimension in pairs(SILE.frames.page.constraints) do
        SILE.frames.page:reifyConstraint(solver, method, true)
      end
      SILE.frames.page:addWidthHeightDefinitions(solver)
    end

    for id, frame in pairs(SILE.frames) do
      if not (id == "page") then
        for method, dimension in pairs(frame.constraints) do
          frame:reifyConstraint(solver, method)
        end
        frame:addWidthHeightDefinitions(solver)
      end
    end
    solver:solve()
    solverNeedsReloading = false
    --SILE.repl()
  end
}

function SILE.framePrototype:toString()
  local str = "<Frame: " .. self.id .. ": "
  str = str .. " next=" .. self.next .. " "
  for method, dimension in pairs(self.constraints) do
    str = str .. method .. "=" .. dimension .. "; "
  end
  str = str .. ">"
  return str
end

function SILE.framePrototype:advanceWritingDirection(amount)
  if type(amount) == "table" then
    if amount.prototype and amount:prototype() == "RelativeMeasurement" then
      amount = amount:absolute()
    else
      SU.error("Table passed to advanceWritingDirection", 1)
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
end

function SILE.framePrototype:advancePageDirection(amount)
  if type(amount) == "table" then SU.error("Table passed to advancePageDirection", 1) end
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

function SILE.framePrototype:newLine()
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

function SILE.framePrototype:lineWidth()
  if self:writingDirection() == "LTR" or self:writingDirection() == "RTL" then
    return self:width()
  else
    return self:height()
  end
end

function SILE.framePrototype:pageTarget()
  if self:pageAdvanceDirection() == "TTB" or self:pageAdvanceDirection() == "BTT" then
    return self:height()
  else
    return self:width()
  end
end

function SILE.framePrototype:init()
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
end

function SILE.framePrototype:enter()
  for i = 1,#self.enterHooks do
    self.enterHooks[i](self)
  end
end

function SILE.framePrototype:leave()
  for i = 1,#self.leaveHooks do
    self.leaveHooks[i](self)
  end
end

function SILE.framePrototype:isAbsoluteConstraint(method)
  if not self.constraints[method] then return false end
  local constraint = parseFrameDef(self.constraints[method])
  if type(constraint) ~= "table" then return true end
  if not constraint.terms then return false end
  for clv,coeff in pairs(constraint.terms) do
    if clv.name and not clv.name:match("^page_") then
      return false
    end
  end
  return true
end

function SILE.framePrototype:isMainContentFrame()
  local frame =  SILE.documentState.thisPageTemplate.firstContentFrame
  while frame do
    if frame == self then return true end
    if frame.next then frame = SILE.getFrame(frame.next) else return false end
  end
  return false
end

SILE.newFrame = function(spec, prototype)
  SU.required(spec, "id", "frame declaration")
  prototype = prototype or SILE.framePrototype
  local frame
  frame = prototype {
    constraints = {},
    variables = {}
  }
  -- Copy everything in from spec
  SILE.frames[spec.id] = frame

  for method, dimension in pairs(dims) do
    frame.variables[method] = cassowary.Variable({ name = spec.id .. "_" .. method })
    frame[method] = function (frame)
      frame:solve()
      return frame.variables[method].value
    end
  end

  for key, value in pairs(spec) do
    if not dims[key] then frame[key] = spec[key] end
  end
  -- Fix up "balanced"
  if frame.balanced == "true" or frame.balanced == "1" then
    frame.balanced = true
  end

  frame.constraints = {}
  -- Add definitions of width and height
  for method, dimension in pairs(dims) do
    if spec[method] then
      frame:constrain(method, spec[method])
    end
  end
  return frame
end

SILE.getFrame = function(id)
  if type(id) == "table" then return id end -- Shouldn't happen but...
  return SILE.frames[id]
  -- or SU.warn("Couldn't get frame ID "..id, true)
end

SILE.parseComplexFrameDimension = function(dimension, width_or_height)
  local length =  parseFrameDef(dimension)
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

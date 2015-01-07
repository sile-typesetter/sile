local cassowary = require("cassowary")
SILE.frames = {}
local solver = cassowary.SimplexSolver();
solverNeedsReloading = true

local parseFrameDef = function(d, width_or_height)
  SILE.documentState._dimension = width_or_height; -- ugly hack since you can't pass state to the parser
  return SILE._frameParser:match(d);
end

SILE.framePrototype = std.object {
  next= nil,
  id= nil,
  previous= nil,
  balanced= 0,
  direction = nil,
  state = {},
  enterHooks = {},
  leaveHooks = {},
  constrain = function (self, method, value)
    self.constraints[method] = value
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
    local dims = { top="h", bottom="h", height="h", left="w", right="w", width="w"}
    local c = parseFrameDef(self.constraints[method], dims[method])
    --print("Adding constraint "..self.id.."("..method..") = "..self.constraints[method])
    local eq = cassowary.Equation(self.variables[method],c)
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
    solver = cassowary.SimplexSolver();
    if SILE.frames.page then
      for k,c in pairs(SILE.frames.page.constraints) do
        SILE.frames.page:reifyConstraint(solver, k, true)
      end
      SILE.frames.page:addWidthHeightDefinitions(solver)
    end

    for id,f in pairs(SILE.frames) do
      if not (id == "page") then
        for k,c in pairs(f.constraints) do
          f:reifyConstraint(solver, k)
        end
        f:addWidthHeightDefinitions(solver)
      end
    end
    solver:solve()
    solverNeedsReloading = false
    --SILE.repl()
  end
};

function SILE.framePrototype:toString()
  local f = "<Frame: "..self.id..": "
  for k,v in pairs(self.constraints) do
    f = f .. k.."="..v.."; "
  end
  f = f.. ">"
  return f
end

function SILE.framePrototype:moveX(amount)
  if self.direction == "RTL" then
    self.state.cursorX = self.state.cursorX - amount
  else
    self.state.cursorX = self.state.cursorX + amount
  end
  self:normalize()
end

function SILE.framePrototype:moveY(amount)
  self.state.cursorY = self.state.cursorY + amount
  self:normalize()
end

function SILE.framePrototype:newLine()
  self.state.cursorX = self.direction == "RTL" and self:right() or self:left()
end

function SILE.framePrototype:init()
  self.state = {
    cursorY = self:top(),
    totals = { height= 0, pastTop = false }
  }
  self:enter()
  self:newLine()
end

function SILE.framePrototype:enter()
  for i = 1,#SILE.framePrototype.enterHooks do
    SILE.framePrototype.enterHooks[i](self)
  end
end

function SILE.framePrototype:leave()
  for i = 1,#self.leaveHooks do
    self.leaveHooks[i](self)
  end
end

function SILE.framePrototype:normalize()
  if (type(self.state.cursorY)) == "table" then self.state.cursorY  =self.state.cursorY.length end
  if (type(self.state.cursorX)) == "table" then self.state.cursorX  =self.state.cursorX.length end
end

SILE.newFrame = function(spec)
  SU.required(spec, "id", "frame declaration")
  local dims = { top="h", bottom="h", height="h", left="w", right="w", width="w"}

  local frame 
  if not SILE.frames[spec.id] then 
    frame = SILE.framePrototype {
      constraints = {},
      variables = {}
    }
    -- Copy everything in from spec
    SILE.frames[spec.id] = frame

    for method, dimension in pairs(dims) do
      frame.variables[method] = cassowary.Variable({ name = spec.id .. "_" .. method });
      frame[method] = function (frame)
        frame:solve()
        return frame.variables[method].value
      end
    end
  else
    frame = SILE.frames[spec.id]
  end

  for key, value in pairs(spec) do
    if not dims[key] then frame[key] = spec[key] end
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

SILE.getFrame = function(id) return SILE.frames[id] or SU.error("Couldn't get frame ID "..id, true) end

SILE._frameParser = require("core/frameparser")

SILE.parseComplexFrameDimension = function(d, width_or_height)
  SILE.documentState._dimension = width_or_height; -- ugly hack since you can't pass state to the parser
  local v =  SILE._frameParser:match(d);
  if type(v) == "table" then
    local g = cassowary.Variable({ name = "t" })
    local eq = cassowary.Equation(g,v)
    solverNeedsReloading = true
    solver:addConstraint(eq)
    SILE.frames.page:solve()
    solverNeedsReloading = true
    return g.value
  end
  return v
end

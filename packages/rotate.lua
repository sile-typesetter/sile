if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("rotating package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

local enter = function(self) 
  if not self.rotate then return end 
  local x = -math.rad(self.rotate)
  -- Keep center point the same
  pdf:gsave()
  local cx = (self:left() + self:width() / 2) 
  local cy = -((self:top() + self:bottom()) / 2) -- Trial and error, just like everything else.

  pdf.setmatrix(1,0,0,1,cx,cy)
  pdf.setmatrix(math.cos(x), math.sin(x), -math.sin(x), math.cos(x), 0, 0)
  pdf.setmatrix(1,0,0,1,-cx,-cy)
end

local leave =   function(self)
  if not self.rotate then return end
  pdf:grestore()
end

if SILE.typesetter.frame then 
  enter(SILE.typesetter.frame)
  table.insert(SILE.typesetter.frame.leaveHooks, leave)
end

table.insert(SILE.framePrototype.enterHooks, enter)
table.insert(SILE.framePrototype.leaveHooks, leave)

-- This code in't there yet.

-- SILE.registerCommand("rotate", function(options, content)
--   local x = math.rad(SU.required(options, "angle", "rotate command"))
--   local hbox = SILE.Commands["hbox"]({}, content)

--   pdf.gsave()
--   pdf.setmatrix(math.cos(x), math.sin(x), -math.sin(x), math.cos(x), 0, 0)
--   pdf.grestore()
-- end)
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

-- What is the width, depth and height of a rectangle width w and height h rotated by angle theta?
-- rect1 = Rectangle[{0, 0}, {w, h}]
-- {{xmin, xmax}, {ymin, ymax}} = Refine[RegionBounds[TransformedRegion[rect1, 
--                                                     RotationTransform[theta, {w/2,h/2}]]],
--                                      w > 0 && h > 0 && theta > 0 && theta < 2 Pi ]
-- PiecewiseExpand[xmax - xmin]
    -- \[Piecewise]  -w Cos[theta]-h Sin[theta]  Sin[theta]<=0&&Cos[theta]<=0
    --                w Cos[theta]-h Sin[theta]  Sin[theta]<=0&&Cos[theta]>0
    --               -w Cos[theta]+h Sin[theta]  Sin[theta]>0&&Cos[theta]<=0
    --                w Cos[theta]+h Sin[theta]  True

local outputRotatedHbox = function (self, typesetter,line)
  local origbox = self.value.orig
  local x = self.value.theta
  -- Find origin of untransformed hbox
  local save = typesetter.frame.state.cursorX
  typesetter.frame.state.cursorX = typesetter.frame.state.cursorX - (origbox.width.length-self.width)/2
  
  local horigin = typesetter.frame.state.cursorX + origbox.width.length / 2
  local vorigin = -(typesetter.frame.state.cursorY - (origbox.height) /2)
  pdf:gsave()
  pdf.setmatrix(1,0,0,1,horigin,vorigin)
  pdf.setmatrix(math.cos(x), math.sin(x), -math.sin(x), math.cos(x), 0, 0)
  pdf.setmatrix(1,0,0,1,-horigin,-vorigin)
  origbox:outputYourself(typesetter,line)
  pdf:grestore()
  typesetter.frame.state.cursorX = save
  typesetter.frame:moveX(self.width)
end

SILE.registerCommand("rotate", function(options, content)
  local theta = -math.rad(SU.required(options, "angle", "rotate command"))
  local origbox = SILE.Commands["hbox"]({}, content)
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  local h = (origbox.height + origbox.depth)
  local w = origbox.width.length
  local st = math.sin(theta)
  local ct = math.cos(theta)
  local height, width, depth
  if st <= 0 and ct <= 0    then 
    width  = -w * ct - h * st
    height = 0.5*(h-h*ct-w*st)
    depth  = 0.5*(h+h*ct+w*st)
  elseif st <=0 and ct > 0  then 
    width  =  w * ct - h * st
    height = 0.5*(h+h*ct-w*st)
    depth  = 0.5*(h-h*ct+w*st)
  elseif st > 0 and ct <= 0 then
    width  = -w * ct + h * st
    height = 0.5*(h-h*ct+w*st)
    depth  = 0.5*(h+h*ct-w*st)
  else
    width  =  w * ct + h * st
    height = 0.5*(h+h*ct+w*st)
    depth  = 0.5*(h-h*ct-w*st)
  end
  depth = -depth
  if depth < 0 then depth = 0 end
  SILE.typesetter:pushHbox({ 
    value = { orig = origbox, theta = theta},
    height = height,
    width = width,
    depth = depth,
    outputYourself= outputRotatedHbox
  });
end)
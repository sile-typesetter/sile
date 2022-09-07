local base = require("packages.base")

local package = pl.class(base)
package._name = "rotate"

local pdf = require("justenoughlibtexpdf")

local enter = function (self, _)
  if not self.rotate then return end
  local x = -math.rad(self.rotate)
  -- Keep center point the same
  pdf:gsave()
  local cx = self:left():tonumber()
  local cy = -self:bottom():tonumber()
  pdf.setmatrix(1, 0, 0, 1, cx + math.sin(x) * self:height():tonumber(), cy)
  pdf.setmatrix(math.cos(x), math.sin(x), -math.sin(x), math.cos(x), 0, 0)
  pdf.setmatrix(1, 0, 0, 1, -cx, -cy)
end

local leave =   function(self, _)
  if not self.rotate then return end
  pdf:grestore()
end

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

local outputRotatedHbox = function (self, typesetter, line)
  local origbox = self.value.orig
  local x = self.value.theta
  -- Find origin of untransformed hbox
  local save = typesetter.frame.state.cursorX
  typesetter.frame.state.cursorX = typesetter.frame.state.cursorX - (origbox.width.length-self.width)/2

  local horigin = (typesetter.frame.state.cursorX + origbox.width.length / 2):tonumber()
  local vorigin = -(typesetter.frame.state.cursorY - origbox.height / 2):tonumber()
  pdf:gsave()
  pdf.setmatrix(1, 0, 0, 1, horigin, vorigin)
  pdf.setmatrix(math.cos(x), math.sin(x), -math.sin(x), math.cos(x), 0, 0)
  pdf.setmatrix(1, 0, 0, 1, -horigin, -vorigin)
  origbox:outputYourself(typesetter, line)
  pdf:grestore()
  typesetter.frame.state.cursorX = save
  typesetter.frame:advanceWritingDirection(self.width)
end

function package:_init ()
  base._init(self)
  if SILE.typesetter and SILE.typesetter.frame then
    enter(SILE.typesetter.frame, SILE.typesetter)
    table.insert(SILE.typesetter.frame.leaveHooks, leave)
  end
  table.insert(SILE.framePrototype.enterHooks, enter)
  table.insert(SILE.framePrototype.leaveHooks, leave)
end

function package:registerCommands ()

  self:registerCommand("rotate", function(options, content)
    local angle = SU.required(options, "angle", "rotate command")
    local theta = -math.rad(angle)
    local origbox = SILE.call("hbox", {}, content)
    SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
    local h = origbox.height + origbox.depth
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
    if depth < SILE.length(0) then depth = SILE.length(0) end
    SILE.typesetter:pushHbox({
      value = { orig = origbox, theta = theta},
      height = height,
      width = width,
      depth = depth,
      outputYourself = outputRotatedHbox
    })
  end)

end

package.documentation = [[
\begin{document}
\use[module=packages.rotate]
The \autodoc:package{rotate} package allows you to rotate things. You can rotate entire
frames, by adding the \autodoc:parameter{rotate=<angle>} declaration to your frame declaration,
and you can rotate any content by issuing the command \autodoc:command{\rotate[angle=<angle>]{<content>}},
where the angle is measured in degrees.

Content which is rotated is placed in a box and rotated. The height and width of
the rotated box is measured, and then put into the normal horizontal list for
typesetting. The effect of this is that space is reserved around the rotated content.
The best way to understand this is by example: here is some text rotated by
\rotate[angle=10]{ten}, \rotate[angle=20]{twenty} and \rotate[angle=40]{forty} degrees.

The previous line was produced by the following code:

\begin{verbatim}
\line
here is some text rotated by
\\rotate[angle=10]\{ten\}, \\rotate[angle=20]\{twenty\} and \\rotate[angle=40]\{forty\} degrees.
\line
\end{verbatim}
\end{document}
]]

return package

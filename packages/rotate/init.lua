local base = require("packages.base")

local package = pl.class(base)
package._name = "rotate"

local enter = function (self, _)
   -- Probably broken, see:
   -- https://github.com/sile-typesetter/sile/issues/427
   if not self.rotate then
      return
   end
   if not SILE.outputter.enterFrameRotate then
      return SU.warn(
         "Frame '"
            .. self.id("' will not be rotated: backend '")
            .. SILE.outputter._name
            .. "' does not support rotation"
      )
   end
   local theta = -math.rad(self.rotate)
   -- Keep center point the same
   local x0 = self:left():tonumber()
   local x1 = x0 + math.sin(theta) * self:height():tonumber()
   local y0 = self:bottom():tonumber()
   SILE.outputter:enterFrameRotate(x0, x1, y0, theta) -- Unstable API
end

local leave = function (self, _)
   if not self.rotate then
      return
   end
   if not SILE.outputter.enterFrameRotate then
      return
   end -- no enter no leave.
   SILE.outputter:leaveFrameRotate()
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
   local theta = self.value.theta

   -- Find origin of untransformed hbox
   local X = typesetter.frame.state.cursorX
   local Y = typesetter.frame.state.cursorY
   typesetter.frame.state.cursorX = X - (origbox.width.length - self.width) / 2
   local horigin = X + origbox.width.length / 2
   local vorigin = Y - (origbox.height - origbox.depth) / 2

   SILE.outputter:rotateFn(horigin, vorigin, theta, function ()
      origbox:outputYourself(typesetter, line)
   end)
   typesetter.frame.state.cursorX = X
   typesetter.frame.state.cursorY = Y
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
   self.commands:register("rotate", function (options, content)
      if not SILE.outputter.rotateFn then
         SU.warn("Output will not be rotated: backend '" .. SILE.outputter._name .. "' does not support rotation")
         return SILE.process(content)
      end
      local angle = SU.required(options, "angle", "rotate command")
      local theta = -math.rad(angle)
      local origbox, hlist = SILE.typesetter:makeHbox(content)
      local h = origbox.height + origbox.depth
      local w = origbox.width.length
      local st = math.sin(theta)
      local ct = math.cos(theta)
      local height, width, depth
      if st <= 0 and ct <= 0 then
         width = -w * ct - h * st
         height = 0.5 * (h - h * ct - w * st)
         depth = 0.5 * (h + h * ct + w * st)
      elseif st <= 0 and ct > 0 then
         width = w * ct - h * st
         height = 0.5 * (h + h * ct - w * st)
         depth = 0.5 * (h - h * ct + w * st)
      elseif st > 0 and ct <= 0 then
         width = -w * ct + h * st
         height = 0.5 * (h - h * ct + w * st)
         depth = 0.5 * (h + h * ct - w * st)
      else
         width = w * ct + h * st
         height = 0.5 * (h + h * ct + w * st)
         depth = 0.5 * (h - h * ct - w * st)
      end
      depth = -depth
      if depth < SILE.types.length(0) then
         depth = SILE.types.length(0)
      end
      SILE.typesetter:pushHbox({
         value = { orig = origbox, theta = theta },
         height = height,
         width = width,
         depth = depth,
         outputYourself = outputRotatedHbox,
      })
      SILE.typesetter:pushHlist(hlist)
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
typesetting. The effect is that space is reserved around the rotated content.
The best way to understand this is by example: here is some text rotated by
\rotate[angle=10]{ten}, \rotate[angle=20]{twenty}, and \rotate[angle=40]{forty} degrees.

The previous line was produced by the following code:

\begin[type=autodoc:codeblock]{raw}
here is some text rotated by
\rotate[angle=10]{ten}, \rotate[angle=20]{twenty}, and \rotate[angle=40]{forty} degrees.
\end{raw}
\end{document}
]]

return package

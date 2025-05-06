local base = require("packages.base")

local package = pl.class(base)
package._name = "hanmenkyoshi"

local showHanmenYoko = function (frame)
   local g = frame:top()
   while g < frame:bottom() do
      SILE.outputter:drawRule(frame:left(), g - 0.25, frame:width(), 0.5)
      local l = frame:left()
      while l <= frame:right() do
         SILE.outputter:drawRule(l - 0.25, g + frame.hanmen.gridsize - 0.25, 0.5, -frame.hanmen.gridsize)
         l = l + frame.hanmen.gridsize
      end
      g = g + frame.hanmen.gridsize
      SILE.outputter:drawRule(frame:left(), g - 0.25, frame:width(), 0.5)
      g = g + frame.hanmen.linegap
   end
end

local showHanmenTate = function (frame)
   local g = frame:right()
   while g > frame:left() do
      SILE.outputter:drawRule(g - 0.25, frame:top(), 0.5, -frame:height())
      local l = frame:top()
      while l < frame:bottom() do
         SILE.outputter:drawRule(g - frame.hanmen.gridsize - 0.25, l - 0.25, frame.hanmen.gridsize, 0.5)
         l = l + frame.hanmen.gridsize
      end
      g = g - frame.hanmen.gridsize
      SILE.outputter:drawRule(g - 0.25, frame:top(), 0.5, -frame:height())
      g = g - frame.hanmen.linegap
   end
end

-- Warning: this function has side affects and if a real frame is
-- passed as a spec it will be modified in addition to a frame
-- being instantiated in the class page template.
local declareHanmenFrame = function (class, id, spec)
   if spec then
      spec.id = id
   else
      spec = id
   end
   spec.hanmen = {
      gridsize = SU.required(spec, "gridsize", "declaring the kihonhanmen", "measurement"),
      linegap = SU.required(spec, "linegap", "declaring the kihonhanmen", "measurement"),
      linelength = SU.required(spec, "linelength", "declaring the kihonhanmen", "measurement"),
      linecount = SU.required(spec, "linecount", "declaring the kihonhanmen"),
   }
   if spec.tate then
      spec.height = spec.hanmen.gridsize * spec.hanmen.linelength
      spec.width = spec.hanmen.gridsize * spec.hanmen.linecount + spec.hanmen.linegap * (spec.hanmen.linecount - 1)
   else
      spec.width = spec.hanmen.gridsize * spec.hanmen.linelength
      spec.height = spec.hanmen.gridsize * spec.hanmen.linecount + spec.hanmen.linegap * (spec.hanmen.linecount - 1)
   end
   local skip = spec.hanmen.linegap + spec.hanmen.gridsize
   class.settings:set("document.baselineskip", SILE.types.node.vglue(skip))
   class.settings:set("document.parskip", SILE.types.node.vglue())
   local frame = SILE.newFrame(spec, spec.tate and SILE.tateFramePrototype or SILE.framePrototype)
   if spec.id then
      class.pageTemplate.frames[spec.id] = frame
   end
end

function package:_init ()
   base._init(self)
   self:loadPackage("tate")
   self:export("declareHanmenFrame", declareHanmenFrame)
end

function package:registerCommands ()
   self.commands:register("show-hanmen", function (_, _)
      local frame = SILE.typesetter.frame
      if not frame.hanmen then
         SU.error("show-hanmen called on a frame with no hanmen")
      end
      local color = SILE.types.color({ r = 1, g = 0.9, b = 0.9 })
      SILE.outputter:pushColor(color)
      if frame:writingDirection() == "TTB" then
         showHanmenTate(frame)
      else
         showHanmenYoko(frame)
      end
      SILE.outputter:popColor()
   end)
end

package.documentation = [[
\begin{document}
Japanese documents are traditionally typeset on a grid layout called a \em{hanmen}, with each character essentially monospaced inside the grid (like writing on graph paper).
The \autodoc:package{hanmenkyoshi} package provides tools to Japanese class designers for creating \em{hanmen} frames with correctly spaced grids.
It also provides the \autodoc:command{\show-hanmen} command for debugging the grid.

The name \em{hanmenkyoshi} is a terrible pun.
\end{document}
]]

return package

local base = require("packages.base")

local package = pl.class(base)
package._name = "tate"

SILE.tateFramePrototype = pl.class(SILE.framePrototype)
SILE.tateFramePrototype.direction = "TTB-RTL"

SILE.tateFramePrototype.enterHooks = {
   function (_, typesetter)
      SILE.typesetters.tate:cast(typesetter)
   end,
}

SILE.tateFramePrototype.leaveHooks = {
   function (_, typesetter)
      SILE.typesetters.base:cast(typesetter)
   end,
}

SILE.newTateFrame = function (spec)
   return SILE.newFrame(spec, SILE.tateFramePrototype)
end

local outputLatinInTate = function (self, typesetter, line)
   -- My baseline moved
   typesetter.frame:advanceWritingDirection(SILE.types.measurement("-0.5zw"))
   typesetter.frame:advancePageDirection(SILE.types.measurement("0.25zw"))

   local vorigin = -typesetter.frame.state.cursorY
   self:oldOutputYourself(typesetter, line)
   typesetter.frame.state.cursorY = -vorigin
   typesetter.frame:advanceWritingDirection(self:lineContribution())
   -- My baseline moved
   typesetter.frame:advanceWritingDirection(SILE.types.measurement("0.5zw"))
   typesetter.frame:advancePageDirection(-SILE.types.measurement("0.25zw"))
end

local outputTateChuYoko = function (self, typesetter, line)
   -- My baseline moved
   local em = SILE.types.measurement("1zw")
   typesetter.frame:advanceWritingDirection(-em + em / 4 - self:lineContribution() / 2)
   typesetter.frame:advancePageDirection(2 * self.height - self.width / 2)
   self:oldOutputYourself(typesetter, line)
   typesetter.frame:advanceWritingDirection(-self:lineContribution() * 1.5 + self.height * 3 / 4)
end

function package:registerCommands ()
   self:registerCommand("tate-frame", function (options, _)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newTateFrame(options)
   end, "Declares (or re-declares) a frame on this page.")

   -- Eventually will be automatically called by script detection, but for now
   -- called manually
   self:registerCommand("latin-in-tate", function (_, content)
      if SILE.typesetter.frame:writingDirection() ~= "TTB" then
         return SILE.process(content)
      end
      local nodes
      local oldT = SILE.typesetter
      local prevDirection = oldT.frame.direction
      self:loadPackage("rotate")
      SILE.settings:temporarily(function ()
         local latinTypesetter = pl.class(SILE.typesetters.base)
         local dummyFrame = pl.class(SILE.framePrototype)
         dummyFrame.init = function (f)
            f.state = {}
         end
         latinTypesetter.initFrame = function (typesetter, frame)
            typesetter.frame = frame
         end
         local frame = dummyFrame({}, true)
         SILE.typesetter = latinTypesetter(frame)
         SILE.settings:set("document.language", "und")
         SILE.settings:set("font.direction", "LTR")
         SILE.process(content)
         nodes = SILE.typesetter.state.nodes
         SILE.typesetter:shapeAllNodes(nodes)
         SILE.typesetter.frame.direction = prevDirection
      end)
      SILE.typesetter = oldT
      SILE.typesetter:pushGlue({
         width = SILE.types.length("0.5zw", "0.25zw", "0.25zw"):absolute(),
      })
      for i = 1, #nodes do
         if SILE.typesetter.frame:writingDirection() ~= "TTB" or nodes[i].is_glue then
            SILE.typesetter:pushHorizontal(nodes[i])
         elseif nodes[i]:lineContribution():tonumber() > 0 then
            local hbox = SILE.call("hbox", {}, function ()
               SILE.typesetter:pushHorizontal(nodes[i])
            end)
            -- Turn off all complex flags.
            for j = 1, #hbox.value do
               for k = 1, #hbox.value[j].nodes do
                  hbox.value[j].nodes[k].value.complex = false
               end
            end
            hbox.oldOutputYourself = hbox.outputYourself
            hbox.outputYourself = outputLatinInTate
         end
      end
   end, "Typeset rotated Western text in vertical Japanese")

   self:registerCommand("tate-chu-yoko", function (_, content)
      if SILE.typesetter.frame:writingDirection() ~= "TTB" then
         return SILE.process(content)
      end
      -- SILE.typesetter:pushGlue({
      --   width = SILE.types.length("0.5zw", "0.25zw", "0.25zw"):absolute() })
      -- })
      SILE.settings:temporarily(function ()
         SILE.settings:set("document.language", "und")
         SILE.settings:set("font.direction", "LTR")
         SILE.call("rotate", { angle = -90 }, function ()
            local hbox = SILE.call("hbox", {}, content)
            hbox.misfit = true
            hbox.oldOutputYourself = hbox.outputYourself
            hbox.outputYourself = outputTateChuYoko
         end)
      end)
      -- SILE.typesetter:pushGlue({
      --   width = SILE.types.length("0.5zw", "0.25zw", "0.25zw"):absolute() })
      -- })
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{tate} package provides support for Japanese vertical typesetting.
It allows for the definition of vertical-oriented frames, as well as for two specific typesetting techniques required in vertical documents: \autodoc:command{\latin-in-tate} typesets its content as Latin text rotated 90 degrees, and \autodoc:command{\tate-chu-yoko} places (Latin) text horizontally within a single grid-square of the vertical \em{hanmen}.
\end{document}
]]

return package

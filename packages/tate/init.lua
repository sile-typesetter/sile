local base = require("packages.base")

local package = pl.class(base)
package._name = "tate"

package._tateFrame = pl.class(SILE.types.frame)
package._tateFrame.direction = "TTB-RTL"
package._tateFrame.enterHooks = {
   function (_, typesetter)
      SILE.typesetters.tate:cast(typesetter)
   end,
}
package._tateFrame.leaveHooks = {
   function (_, typesetter)
      SILE.typesetters.base:cast(typesetter)
   end,
}

package._dummyFrame = pl.class(SILE.types.frame)
package._dummyFrame.init = function (frame, _typesetter)
   frame.state = {}
end

SILE.newTateFrame = function (spec)
   SU.deprecated("SILE.newTateFrame", "packages.tate._tateFrame", "0.16.0", "0.17.0")
   return SILE.newFrame(spec, package._tateFrame)
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
   self.commands:register("tate-frame", function (options, _)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newTateFrame(options)
   end, "Declares (or re-declares) a frame on this page.")

   -- Eventually will be automatically called by script detection, but for now
   -- called manually
   self.commands:register("latin-in-tate", function (_, content)
      if SILE.typesetter.frame:writingDirection() ~= "TTB" then
         return SILE.process(content)
      end
      local nodes
      local oldT = SILE.typesetter
      local prevDirection = oldT.frame.direction
      self:loadPackage("rotate")
      self.settings:temporarily(function ()
         local frame = self._dummyFrame({ id = "dummy" }, true)
         SILE.typesetter = SILE.typesetters["latin-in-tate"](frame)
         self.settings:set("document.language", "und")
         self.settings:set("font.direction", "LTR")
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

   self.commands:register("tate-chu-yoko", function (_, content)
      if SILE.typesetter.frame:writingDirection() ~= "TTB" then
         return SILE.process(content)
      end
      -- SILE.typesetter:pushGlue({
      --   width = SILE.types.length("0.5zw", "0.25zw", "0.25zw"):absolute() })
      -- })
      self.settings:temporarily(function ()
         self.settings:set("document.language", "und")
         self.settings:set("font.direction", "LTR")
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

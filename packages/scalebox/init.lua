local base = require("packages.base")

local package = pl.class(base)
package._name = "scalebox"

function package:registerCommands ()
   self.commands:register("scalebox", function (options, content)
      if not SILE.outputter.scaleFn then
         SU.warn("Output will not be scaled: backend '" .. SILE.outputter._name .. "' does not support scaling")
         return SILE.process(content)
      end

      local hbox, hlist = SILE.typesetter:makeHbox(content)
      local xratio, yratio = SU.cast("number", options.xratio or 1), SU.cast("number", options.yratio or 1)
      if xratio == 0 or yratio == 0 then
         SU.error("Scaling ratio cannot be null")
      end

      local W = hbox.width * math.abs(xratio)
      local H, D
      if yratio > 0 then
         H = hbox.height * yratio
         D = hbox.depth * yratio
      else
         H = hbox.depth * -yratio
         D = hbox.height * -yratio
      end

      SILE.typesetter:pushHbox({
         width = W,
         height = H,
         depth = D,
         outputYourself = function (node, typesetter, line)
            local outputWidth = SU.rationWidth(node.width, node.width, line.ratio)
            local X = typesetter.frame.state.cursorX
            local Y = typesetter.frame.state.cursorY

            if xratio < 0 then
               typesetter.frame:advanceWritingDirection(-outputWidth)
            end
            SILE.outputter:scaleFn(X, Y, xratio, yratio, function ()
               hbox:outputYourself(typesetter, line)
            end)
            typesetter.frame.state.cursorX = X
            typesetter.frame.state.cursorY = Y
            typesetter.frame:advanceWritingDirection(outputWidth)
         end,
      })
      SILE.typesetter:pushHlist(hlist)
   end, "Scale content by some horizontal and vertical ratios")
end

package.documentation = [[
\begin{document}
The \autodoc:package{scalebox} package allows to scale any content by some horizontal
and vertical ratios, by issuing the command
\autodoc:command{\scalebox[xratio=<number>, yratio=<number>]{<content>}},
where the ratios are optional non-null numbers (defaulting to 1).
The content is placed in a box and scaled.

Here is an \scalebox[xratio=0.75, yratio=1.25]{example}.

The previous line was produced by the following code:

\begin[type=autodoc:codeblock]{raw}
Here is an \scalebox[xratio=0.75, yratio=1.25]{example}.
\end{raw}
\end{document}
]]

return package

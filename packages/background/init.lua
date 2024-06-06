local base = require("packages.base")

local package = pl.class(base)
package._name = "background"

local background = {}

local outputBackground = function ()
   local pagea = SILE.getFrame("page")
   local offset = SILE.documentState.bleed / 2
   if type(background.bg) == "string" then
      SILE.outputter:drawImage(
         background.bg,
         pagea:left() - offset,
         pagea:top() - offset,
         pagea:width() + 2 * offset,
         pagea:height() + 2 * offset
      )
   elseif background.bg then
      SILE.outputter:pushColor(background.bg)
      SILE.outputter:drawRule(
         pagea:left() - offset,
         pagea:top() - offset,
         pagea:width() + 2 * offset,
         pagea:height() + 2 * offset
      )
      SILE.outputter:popColor()
   end
   if not background.allpages then
      background.bg = nil
   end
end

function package:_init ()
   base._init(self)
   self.class:registerHook("newpage", outputBackground)
end

function package:registerCommands ()
   self:registerCommand("background", function (options, _)
      if SU.boolean(options.disable, false) then
         -- This option is certainly better than enforcing a white color.
         background.bg = nil
         return
      end

      local allpages = SU.boolean(options.allpages, true)
      background.allpages = allpages
      local color = options.color and SILE.types.color(options.color)
      local src = options.src
      if src then
         background.bg = src and SILE.resolveFile(src) or SU.error("Couldn't find file " .. src)
      elseif color then
         background.bg = color
      else
         SU.error("background requires a color or an image src parameter")
      end
      outputBackground()
   end, "Output a solid background color <color> or an image <src> on pages after initialization.")
end

package.documentation = [[
\begin{document}
\use[module=packages.background]
As its name implies, the \autodoc:package{background} package allows you to set the color of the page canvas background or to use a background image extending to the full page width and height.

The package provides a \autodoc:command{\background} command which requires one of the following parameters:
\begin{itemize}
\item{\autodoc:parameter{color=<color specification>} sets the background of the current and all following pages to that color. The color specification has the same syntax as specified in the \autodoc:package{color} package.}
\item{\autodoc:parameter{src=<file>} sets the backgound of the current and all following pages to the specified image. The latter will be scaled to the target dimension.}
\end{itemize}

The background extends to the page trim area (“page bleed”) if the latter is defined.
This is to ensure that it indeed “bleeds” off the sides of the page, so as to avoid thin white lignes on an otherwise full color page when the paper sheet is cut to dimension but some pages are trimmed slightly more than others.
If setting only the current page background different from the default is desired, an extra parameter \autodoc:parameter{allpages=false} can be passed.

\background[color=#e9d8ba,allpages=false]

So, for example, \autodoc:command{\background[color=#e9d8ba,allpages=false]} will set a sepia tone background on the current page.
The \autodoc:parameter{disable=true} parameter allows disabling the background on the following pages.
It may be useful when \autodoc:parameter{allpages} is active from a previous invocation.
\end{document}
]]

return package

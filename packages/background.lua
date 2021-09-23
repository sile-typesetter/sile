SILE.require("packages/color")

local outputBackground = function (color)
  local page = SILE.getFrame("page")
  local backgroundColor = SILE.colorparser(color)
  SILE.outputter:pushColor(backgroundColor)
  SILE.outputter:drawRule(page:left(), page:top(), page:right(), page:bottom())
  SILE.outputter:popColor()
end

SILE.registerCommand("background", function (options, _)
  options.color = options.color or "white"
  options.allpages = options.allpages or true
  outputBackground(options.color)
  if options.allpages and options.allpages ~= "false" then
    local oldNewPage = SILE.documentState.documentClass.newPage
    SILE.documentState.documentClass.newPage = function (self)
      local page = oldNewPage(self)
      outputBackground(options.color)
      return page
    end
  end
end, "Draws a solid background color <color> on pages after initialization.")

return { documentation = [[\begin{document}
The \code{background} package allows you to set the color of the canvas
background (by drawing a solid color block the full size of the page on page
initialization). The package provides a \code{\\background} command which
requires at least one parameter,
\code{color=\em{<color \nobreak{}specification}}, and sets the backgound of the
current and all following pages to that color. If setting only the current page
background different from the default is desired, an extra parameter
\code{allpages=false} can be passed. The color specification in the same as
specified in the \code{color} package.

\background[color=#e9d8ba,allpages=false]

So, for example, \code{\\background[color=#e9d8ba,allpages=false]} will set a
sepia tone background on the current page.
\end{document}]] }

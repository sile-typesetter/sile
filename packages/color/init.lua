local base = require("packages.base")

local package = pl.class(base)
package._name = "color"

function package:registerCommands ()

  self.class:registerCommand("color", function (options, content)
    local color = SILE.color(options.color or "black")
    SILE.typesetter:pushHbox({
      outputYourself = function () SILE.outputter:pushColor(color) end
    })
    SILE.process(content)
    SILE.typesetter:pushHbox({
      outputYourself = function () SILE.outputter:popColor() end
    })
  end, "Changes the active ink color to the color <color>.")

end

package.documentation = [[
\begin{document}
The \autodoc:package{color} package allows you to temporarily change the color of the (virtual) ink that SILE uses to output text and rules.
The package provides a \autodoc:command{\color} command which takes one parameter, \autodoc:parameter{color=<color specification>}, and typesets its argument in that color.

The color specification is one of the following:
\begin{itemize}
\item{A RGB color in \code{#xxx} or \code{#xxxxxx} format, where \code{x} represents a hexadecimal digit, as often seen in HTML/CSS (\code{#000} is black, \code{#fff} is white, \code{#f00} is red and so on);}
\item{A RGB color as a series of three numeric values between 0 and 255 (e.g. \code{0 0 139} is a dark blue) or as three percentages;}
\item{A CMYK color as a series of four numeric values between 0 and 255 or as four percentages;}
\item{A grayscale color as a numeric value between 0 and 255;}
\item{A (case-insensitive) named color, as one of the 148 keywords defined in the CSS Color Module Level 4. (Named colors resolve to RGB in the actual output.)}
\end{itemize}

So, for example, \color[color=red]{this text is typeset with \autodoc:command{\color[color=red]{…}}}.

Here is a rule typeset with \autodoc:command{\color[color=#22dd33]}: \color[color=#ffdd33]{\hrule[width=120pt,height=0.5pt]} \end{document}
]]

return package

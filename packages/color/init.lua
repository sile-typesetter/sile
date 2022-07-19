local function registerCommands (class)

  class:registerCommand("color", function (options, content)
    local color = SILE.colorparser(options.color or "black")
    SILE.typesetter:pushHbox({
      outputYourself = function () SILE.outputter:pushColor(color) end
    })
    SILE.process(content)
    SILE.typesetter:pushHbox({
      outputYourself = function () SILE.outputter:popColor() end
    })
  end, "Changes the active ink color to the color <color>.")

end

return {
  registerCommands = registerCommands,
  documentation = [[\begin{document}
The \autodoc:package{color} package allows you to temporarily change the color of the
(virtual) ink that SILE uses to output text and rules. The package provides
a \autodoc:command{\color} command which takes one parameter,
\autodoc:parameter{color=<color specification>}, and typesets
its argument in that color. The color specification is the same as HTML:
it can be a RGB color value in \code{#xxx} or \code{#xxxxxx} format, where \code{x}
represents a hexadecimal digit (\code{#000} is black, \code{#fff} is white,
\code{#f00} is red and so on), or it can be one of the HTML and CSS named colors.

\note{The HTML and CSS named colors can be found at \code{http://dev.w3.org/csswg/css-color/#named-colors}.}

So, for example, \color[color=red]{this text is typeset with \autodoc:command{\color[color=red]{…}}}.

Here is a rule typeset with \autodoc:command{\color[color=#22dd33]}:
\color[color=#ffdd33]{\hrule[width=120pt,height=0.5pt]}
\end{document}]] }

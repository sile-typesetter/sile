SILE.registerCommand("rebox", function (options, content)
  local box = SILE.call("hbox", {}, content)
  if options.width then box.width = SILE.length(options.width) end
  if options.height then box.height = SILE.length(options.height) end
  if options.depth then box.depth = SILE.length(options.depth) end
  if options.phantom then
    box.outputYourself = function (self, typesetter, line)
      typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
    end
  end
  table.insert(SILE.typesetter.state.nodes, box)
end, "Place the output within a box of specified width, height, depth and visibility")

return {
  documentation = [[
\begin{document}
This package provides the \code{\\rebox} command, which allows you to
lie to SILE about the size of content. You can change the \code{width},
\code{height}, or \code{depth} of your content with the respective
parameters, or make it invisible by using the \code{phantom} parameter.

For example:

\begin{verbatim}
\line
Hello \\rebox[width=0pt]\{world\}overprint.

Look I’m not \\rebox[phantom=true]\{here\}!
\line
\end{verbatim}

\begin{examplefont}
Hello \rebox[width=0pt]{world}overprint.

Look I’m not \rebox[phantom=true]{here}!
\end{examplefont}
\end{document}
]]
}

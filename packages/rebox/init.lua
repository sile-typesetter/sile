local base = require("packages.base")

local package = pl.class(base)
package._name = "rebox"

function package:registerCommands ()

  self:registerCommand("rebox", function (options, content)
    local hbox, hlist = SILE.typesetter:makeHbox(content)
    if options.width then hbox.width = SILE.length(options.width) end
    if options.height then hbox.height = SILE.length(options.height) end
    if options.depth then hbox.depth = SILE.length(options.depth) end
    if options.phantom then
      hbox.outputYourself = function (node, typesetter, line)
        typesetter.frame:advanceWritingDirection(node:scaledWidth(line))
      end
    end
    SILE.typesetter:pushHbox(hbox)
    SILE.typesetter:pushHlist(hlist)
  end, "Place the output within a hbox of specified width, height, depth and visibility")

end

package.documentation = [[
\begin{document}
This package provides the \autodoc:command{\rebox} command, which allows you to lie to SILE about the size of content.
You can change the \autodoc:parameter{width}, \autodoc:parameter{height}, or \autodoc:parameter{depth} of your content with the respective parameters, or make it invisible by setting the \autodoc:parameter{phantom} parameter to \code{true}.

For example:

\begin[type=autodoc:codeblock]{raw}
Hello \rebox[width=0pt]{world}overprint.

Look I’m not \rebox[phantom=true]{here}!
\end{raw}

\begin{autodoc:example}
Hello \rebox[width=0pt]{world}overprint.

Look I’m not \rebox[phantom=true]{here}!
\end{autodoc:example}
\end{document}
]]

return package

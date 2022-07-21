local base = require("packages.base")

local package = pl.class(base)
package._name = "verbatim"

function package:registerCommands ()

  local class = self.class

  class:registerCommand("verbatim:font", function (options, content)
    options.family = options.family or "Hack"
    options.size = options.size or SILE.settings:get("font.size") - 3
    SILE.call("font", options, content)
  end, "The font chosen for the verbatim environment")

  class:registerCommand("verbatim", function (_, content)
    SILE.typesetter:pushVglue(6)
    SILE.typesetter:leaveHmode()
    SILE.settings:temporarily(function()
      SILE.settings:set("typesetter.parseppattern", "\n")
      SILE.settings:set("typesetter.obeyspaces", true)
      SILE.settings:set("document.rskip", SILE.nodefactory.glue("0 plus 10000pt"))
      SILE.settings:set("document.parindent", SILE.nodefactory.glue("0"))
      SILE.settings:set("document.baselineskip", SILE.nodefactory.vglue("0"))
      SILE.settings:set("document.lineskip", SILE.nodefactory.vglue("2pt"))
      SILE.call("verbatim:font")
      SILE.settings:set("document.spaceskip", SILE.length("1spc"))
      SILE.settings:set("shaper.variablespaces", false)
      SILE.settings:set("document.language", "und")
      SILE.process(content)
    end)
    SILE.typesetter:leaveHmode()
  end, "Typesets its contents in a monospaced font.")

  class:registerCommand("obeylines", function (_, content)
    SILE.settings:temporarily(function()
      SILE.settings:set("typesetter.parseppattern", "\n")
      SILE.process(content)
    end)
  end)

end

package.documentation = [[
\begin{document}
The \autodoc:package{verbatim} package is useful when quoting pieces of computer code and other text for which formatting is significant.
It changes SILE’s settings so that text is set ragged right, with no hyphenation, no indentation and regular spacing.
It tells SILE to honor multiple spaces, and sets a monospaced font.

\note{Despite the name, \autodoc:environment{verbatim} does not alter the way that SILE sees special characters.
You still need to escape backslashes and braces: to produce a backslash, you need to write \code{\\\\}.}

Here is some text set in the \autodoc:environment{verbatim} environment:

\begin{verbatim}
local function init (class, _)
  class:loadPackage("rebox")
  class:loadPackage("raiselower")
end
\end{verbatim}

If you want to specify what font the verbatim environment should use, you can redefine the \autodoc:command{\verbatim:font} command.
For example you could change it from XML like this:

\begin{verbatim}
<define command="verbatim:font">
   <font family="DejaVu Sans Mono" size="9pt"/>
</define>
\end{verbatim}
\end{document}
]]

return package

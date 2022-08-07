--
-- Markdown native support for SILE
-- Using the lunamark library.
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "markdown"

function package:_init (_)
  base._init(self)
  self.class:loadPackage("markdown.commands")

  -- Extend inputters if needed.
  -- Chicken and eggs... This just forces the inputter to be loaded!
  local _ = SILE.inputters.markdown
end

package.documentation = [[\begin{document}
The \autodoc:package{markdown} package allows you to use Markdown, with plenty of additional
features and extensions, as your alternative format of choice for documents —without leaving
aside hooks to SILE, when felt necessary\footnote{So you get the best of two worlds, for an
efficient and direct Markdown to PDF conversion.}.

Once you have loaded the package, the \autodoc:command{\include[src=<file>]} command supports
natively reading and processing a Markdown file:

\begin{verbatim}
\\use[module=packages.markdown]
\\include[src=somefile.md]
\end{verbatim}

\smallskip

The speedy Markdown parsing relies on John MacFarlane’s excellent \strong{lunamark} Lua library,
which empovers this package and thus allows native processing of Markdown directly within SILE,
as a first-class language.

A whole dedicated chapter is dedicated to the topic, including a discussion on alternatives,
in an appendix to the SILE manual. Please refer to it for more details and an exhaustive
presentation of the capabilities.
\end{document}]]

return package

--
-- Pandoc JSON AST native support for SILE
-- Focussed on Markdown needs (esp. table support)
--
-- AST conversion relies on the Pandoc types specification:
-- https://hackage.haskell.org/package/pandoc-types
--
-- Reusing the commands made for the "markdown" package.
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "pandocast"


function package:_init (_)
  base._init(self)
  self.class:loadPackage("markdown.commands")

  -- Extend inputters if needed.
  -- Chickend and eggs... This just forces the inputter to be loaded!
  local _ = SILE.inputters.pandocast
end

package.documentation = [[\begin{document}
The \autodoc:package{pandocast} package allows you to use Pandoc’s JSON AST as an input format
for documents.
Pandoc is a free-software document converter, created by the same John MacFarlane who
provided the \strong{lunamark} library which empowers SILE’s \autodoc:package{markdown}
package. The latter, though, does not offer as many options and extensions as Pandoc does,
for advanced typesetting.

Provided Pandoc is installed on your system, you can obtain an AST output from any supported
source format. For instance, Markdown\footnote{There are areas —typically tables— where Pandoc,
being a versatile and generic conversion solution, exceeds the minimum needs for Markdown.
SILE’s converter may not be able to process these correctly.} being our focus here:

\begin{verbatim}
pandoc -t json somefile.md -f markdown -o somefile.pandoc
\end{verbatim}

\smallskip

Once you have loaded this package, the \autodoc:command{\include[src=<file>]} command supports
natively reading and processing such a Pandoc AST file, assuming the \code{.pandoc} extension or
specifying the \autodoc:parameter{format=pandocast} parameter:

\begin{verbatim}
\\use[module=packages.pandocast]
\\include[src=somefile.pandoc]
\end{verbatim}

\smallskip

This package supports quite the same advanced features as the \autodoc:package{markdown}
package, e.g. the ability to use custom styles, to pass native content through to SILE, etc.
While it requires an external tool to be invoked, it may be your fallback solution if the
latter falls short for you and does not support some Markdown extension you would need.

There is a small \em{caveat}, though: one must use a version of Pandoc which generates
an AST compatible with our parser (“inputter”). While the Pandoc AST is somewhat stable,
it may change when new features are introduced in the software.
\end{document}]]

return package

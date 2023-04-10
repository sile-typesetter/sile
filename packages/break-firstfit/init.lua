local base = require("packages.base")

local package = pl.class(base)
package._name = "break-firstfit"

-- Sometimes you just want a simple first-fit paragraph breaking
-- algorithm, especially when you're dealing with vertical
-- typesetting. Oh, and it's really fast too.

function package:_init ()
  base._init(self)
  SILE.typesetters.firstfit:cast(SILE.typesetter)
end

package.documentation = [[
\begin{document}
SILE’s normal page breaking algorithm is based on the Knuth-Plass “best-fit” method, which tests a variety of possible paragraph constructions before deciding on the visually optimal one.
That guarantees great results for texts which require full justification, but some languages don’t need that degree of complexity.
In particular, Japanese is traditionally typeset on a grid system with characters being essentially monospaced.
You don’t need to do anything clever to break that into lines: just stop when you get to the end of the line and start a new one.
This package implements this “first-fit” method.
It’s designed to be used by other packages so it doesn’t currently provide any user-facing commands.
\end{document}
]]

return package

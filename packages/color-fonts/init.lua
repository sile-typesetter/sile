local base = require("packages.base")

local package = pl.class(base)
package._name = "color-fonts"

package.documentation = [[
\begin{document}
The \autodoc:package{color-fonts} package adds support for fonts with multi-colored glyphs (that is,
OpenType fonts with \code{COLR} and \code{CPAL} tables).
This package is automatically loaded when such a font is detected.
\end{document}
]]

return package

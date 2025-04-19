local base = require("packages.base")

local package = pl.class(base)
package._name = "color-fonts"

function package._init (_)
   SU.deprecated(
      "\\use[module=color-fonts]",
      nil,
      "0.16.0",
      "0.17.0",
      [[
         It is no longer necessary to load the color-fonts package. The shaper it
         provided is automatically loaded when a color font is detected.
         ]]
   )
end

package.documentation = [[
\begin{document}
The \autodoc:package{color-fonts} package is obsolete.
The functionality is provided by a shaper module.
The correct shaper will be loaded automatically when support for multi-colored glyphs is needed.
Using OpenType fonts with \code{COLR} and \code{CPAL} tables will trigger the switch.
\end{document}
]]

return package

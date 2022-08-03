local base = require("packages.base")

local package = pl.class(base)
package._name = "barcodes"

function package:_init (_)
  base._init(self)
  self.class:loadPackage("barcodes.ean13")
end

package.documentation = [[
\begin{document}
This package is just a wrapper loading all other barcode-related sub-packages, such
as \autodoc:package{barcodes.ean13}.
\end{document}]]

return package

local base = require("typesetters.base")

local typesetter = pl.class(base)
typesetter._name = "default"

-- Using 'base' directly and typesetters that derive from 'base' give slightly different initialization sequences, which
-- is confusing to debug. In particular _post_init() handling is different.

return typesetter

local base = require("outputters.base")

local outputter = pl.class(base)
outputter._name = "dummy"
outputter.extension = "dummy"

return outputter

local base = require("outputters.base")

local outputter = pl.class(base)
outputter._name = "dummy"

-- Most of the base outputter functions are just empty prototypes, but for the
-- few that actually do something override them...

local _dummy = function () end

outputter.getOutputFilename = _dummy

return outputter

local base = require("outputters.base")

local dummy = pl.class(base)
dummy._name = "dummy"

-- Most of the base outputter functions are just empty prototypes, but for the
-- few that actually do something override them...

local _dummy = function () end

dummy.getOutputFilename = _dummy

return dummy

--- SILE fontmanager class.
-- @interfaces fontmanagers

local module = require("types.module")
local fontmanager = pl.class(module)
fontmanager.type = "fontmanager"

function fontmanager:_init () end

function fontmanager:face (_) end

return fontmanager

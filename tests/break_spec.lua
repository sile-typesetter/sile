testingSILE = true
assert = require "luassert"
SILE = require("core/sile")
SILE.documentState = { documentClass = { state = { } } }
local hlist = require("tests/testdata")

--print(inspect(SILE.linebreak:doBreak({ nodes = hlist, hsize = 250.0, pretolerance = -1 })))

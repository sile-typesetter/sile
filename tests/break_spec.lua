testingSILE = true
SILE = require("core/sile")
local hlist = require("tests/testdata")

print(inspect(SILE.linebreak:doBreak({ nodes = hlist, hsize = 250.0, pretolerance = -1 })))
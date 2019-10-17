SILE = require("core/sile")

SILE.documentState = { documentClass = { state = { } } }
SILE.typesetter:init(SILE.newFrame({id="foo"}))
local hlist = require("tests/testdata")
print(SILE.linebreak:doBreak(hlist, 30.0))

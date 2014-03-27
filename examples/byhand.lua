require("core/sile")
SILE.outputFilename="byhand.pdf"
local plain = require("classes/plain")
plain.options.papersize("a4")
SILE.documentState.documentClass = plain;
local ff = plain:init()
SILE.typesetter:init(ff)
SILE.typesetter:typeset("To Sherlock Holmes she is always the woman. I have seldom heard him mention her under any other name. In his eyes she eclipses and predominates the whole of her sex.")
plain:finish()
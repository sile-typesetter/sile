package.path = (os.getenv("SILE_PATH") and
os.getenv("SILE_PATH").."/?.lua" or "") .. ';?.lua;/usr/local/share/sile/?.lua;/usr/local/share/sile/lua-libraries/?.lua;/usr/local/share/sile/lua-libraries/?/init.lua;lua-libraries/?.lua;lua-libraries/?/init.lua;' .. package.path
package.cpath = package.cpath .. ";core/?.so;/usr/local/lib/sile/?.so;"
require("core/sile")
SILE.init()
SILE.outputFilename="byhand.pdf"
local plain = require("classes/plain", "classes")
plain.options.papersize("a4")
SILE.documentState.documentClass = plain;
local ff = plain:init()
SILE.typesetter:init(ff)
SILE.typesetter:typeset("To Sherlock Holmes she is always the woman. I have seldom heard him mention her under any other name. In his eyes she eclipses and predominates the whole of her sex.")
plain:finish()

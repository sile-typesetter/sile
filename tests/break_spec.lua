package.path = '?.lua;/usr/local/share/sile/?.lua;/usr/local/share/sile/lua-libraries/?.lua;/usr/local/share/sile/lua-libraries/?/init.lua;lua-libraries/?.lua;lua-libraries/?/init.lua;' .. package.path
local pathvar = os.getenv("SILE_PATH")
if pathvar then
    for path in string.gmatch(pathvar, "[^;]+") do
        package.path =  path .. "/?.lua;" .. package.path
    end
end
package.cpath = package.cpath .. ";core/?.so;/usr/local/lib/sile/?.so;"
testingSILE = true
assert = require "luassert"
SILE = require("core/sile")
SILE.documentState = { documentClass = { state = { } } }
SILE.typesetter:init(SILE.newFrame({id="foo"}))
local hlist = require("tests/testdata")
print(SILE.linebreak:doBreak(hlist, 30.0))

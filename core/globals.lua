--- Global library provisions.
-- @module globals
-- @alias _G

--- Penlight.
-- On-demand module loader, provided for SILE and document usage
_G.pl = require("pl.import_into")()

--- UTF-8 String handler.
-- Lua 5.3+ has a UTF-8 safe string function module but it is somewhat
-- underwhelming. This module includes more functions and supports older Lua
-- versions. Docs: https://github.com/starwing/luautf8
_G.luautf8 = require("lua-utf8")

--- Fluent localization library.
_G.fluent = require("fluent")()

-- For developer testing only, usually in CI
if os.getenv("SILE_COVERAGE") then require("luacov") end

--- Global library provisions.
-- @module globals
-- @alias _G

--- Penlight od-demand loader.
-- The Lua language adopts a "no batteries included" philosophy by providing a minimal standard library. Penlight is
-- a widely used set libraries for making it easier to work with common tasks. Loading SILE implies that the PEnlight
-- on-demand module loader is available, allowing any Penlight functions to be accessed using the `pl` prefix. Consult
-- the [Penlight documentation](https://lunarmodules.github.io/Penlight/) for specifics of the utilities available.
_G.pl = require("pl.import_into")()

--- UTF-8 string library.
-- LuaJIT 5.1 and 5.2's `string` module only handle strings as bytes. Lua 5.3+ has a UTF-8 safe `string` module, but its
-- feature set is somewhat underwhelming. This module includes more functions and levels the playing field no matter
-- which Lua VM is being used. See [luautf8 docs](https://github.com/starwing/luautf8) for more details.
_G.luautf8 = require("lua-utf8")

--- Fluent localization library.
-- For handling messages in various languages SILE provides an implementation of [Project
-- Fluent](https://projectfluent.org/)'s localization system (originally developed by Mozilla for use in Firefox). This
-- global is an instantiated interface to [fluent-lua](https://github.com/alerque/fluent-lua) pre-loaded with resources
-- for all the langugaes and regions SILE has support for.
_G.fluent = require("fluent")()

-- For developer testing only, usually in CI
if os.getenv("SILE_COVERAGE") then
   require("luacov")
end

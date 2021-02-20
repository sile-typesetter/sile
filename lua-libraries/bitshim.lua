--[[ This module smooths over all the various Lua bit libraries

Sourced from:
https://github.com/daurnimator/lua-http/blob/v0.3/http/bit.lua

Note using these functions one must me careful to do bit operations only:
  - on bytes (8 bits),
  - with quantities <= LONG_MAX (0x7fffffff)
  - band with 0x80000000 that is subsequently compared with 0
]]

-- Lua 5.3 has built-in bit operators, wrap them in a function.
if _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then
	-- Use debug.getinfo to get correct file+line numbers for loaded snippet
	local info = debug.getinfo(1, "Sl")
	return assert(load(("\n"):rep(info.currentline+1)..[[return {
		band = function(a, b) return a & b end;
		bor = function(a, b) return a | b end;
		bxor = function(a, b) return a ~ b end;
		lshift = function(a, b) return a << b end;
		rshift = function(a, b) return a >> b end;
	}]], info.source))()
end

-- The "bit" library that comes with luajit
-- also available for lua 5.1 as "luabitop": http://bitop.luajit.org/
local has_bit, bit = pcall(require, "bit")
if has_bit then
	return {
		band = bit.band;
		bor = bit.bor;
		bxor = bit.bxor;
		lshift = bit.lshift;
		rshift = bit.rshift;
	}
end

-- The "bit32" library shipped with lua 5.2
local has_bit32, bit32 = pcall(require, "bit32")
if has_bit32 then
	return {
		band = bit32.band;
		bor = bit32.bor;
		bxor = bit32.bxor;
		lshift = bit32.lshift;
		rshift = bit32.rshift;
	}
end

error("Please install a bit library")

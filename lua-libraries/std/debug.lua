--[[--
 Additions to the debug module
 @module std.debug
]]

local init   = require "std.debug_init"
local io     = require "std.io"
local list   = require "std.list"
local string = require "std.string"

--- To activate debugging set _DEBUG either to any true value
-- (equivalent to {level = 1}), or as documented below.
-- @class table
-- @name _DEBUG
-- @field level debugging level
-- @field call do call trace debugging
-- @field std do standard library debugging (run examples & test code)


--- Print a debugging message.
-- @param n debugging level, defaults to 1
-- @param ... objects to print (as for print)
local function say (n, ...)
  local level = 1
  local arg = {n, ...}
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if init._DEBUG and
    ((type (init._DEBUG) == "table" and type (init._DEBUG.level) == "number" and
      init._DEBUG.level >= level)
       or level <= 1) then
    io.writelines (io.stderr, table.concat (list.map (string.tostring, arg), "\t"))
  end
end

--- Trace function calls.
-- Use as debug.sethook (trace, "cr"), which is done automatically
-- when _DEBUG.call is set.
-- Based on test/trace-calls.lua from the Lua distribution.
-- @class function
-- @name trace
-- @param event event causing the call
local level = 0
local function trace (event)
  local t = debug.getinfo (3)
  local s = " >>> " .. string.rep (" ", level)
  if t ~= nil and t.currentline >= 0 then
    s = s .. t.short_src .. ":" .. t.currentline .. " "
  end
  t = getinfo (2)
  if event == "call" then
    level = level + 1
  else
    level = math.max (level - 1, 0)
  end
  if t.what == "main" then
    if event == "call" then
      s = s .. "begin " .. t.short_src
    else
      s = s .. "end " .. t.short_src
    end
  elseif t.what == "Lua" then
    s = s .. event .. " " .. (t.name or "(Lua)") .. " <" ..
      t.linedefined .. ":" .. t.short_src .. ">"
  else
    s = s .. event .. " " .. (t.name or "(C)") .. " [" .. t.what .. "]"
  end
  io.writelines (io.stderr, s)
end

-- Set hooks according to init._DEBUG
if type (init._DEBUG) == "table" and init._DEBUG.call then
  debug.sethook (trace, "cr")
end

--- @export
local M = {
  say   = say,
  trace = trace,
}

for k, v in pairs (debug) do
  M[k] = M[k] or v
end

--- The global function `debug` is an abbreviation for `debug.say (1, ...)`
-- @function debug
-- @see say
local metatable = {
  __call = function (self, ...)
             say (1, ...)
           end,
}

return setmetatable (M, metatable)

-- The loader for individual IO formats for vstruct.
-- Returns the "io function", which is called with:
-- * an IO type, such as 'x' or 'c'
-- * an IO operation, such as 'write' or 'size'
-- * some (type x operation) specific other arguments
-- upon which it will attempt to load the handler for that operation from the
-- module vstruct.io.<type> and call it.

-- Copyright (c) 2011 Ben "ToxicFrog" Kelly

local defaults = require "vstruct.io.defaults"
local mt = { __index = defaults }

local function iorequire(format)
  local r,v = pcall(require, "vstruct.io."..format)

  if not r then
    error("vstruct: no support for format '"..format.."':\n"..tostring(v))
  end

  setmetatable(v, mt)
  
  return v           
end

local controlnames = {
  seekf = "+";
  seekb = "-";
  seekto  = "@";
  bigendian = ">";
  littleendian= "<";
  hostendian  = "=";
}

for name,symbol in pairs(controlnames) do
  package.preload["vstruct.io."..symbol] = function() return iorequire(name) end
end

return function(format, method, ...)
  local fmt = iorequire(format)
  
  assert(fmt[method], "No support for method '"..tostring(method).."' in IO module '"..format.."'")
  
  return fmt[method](...)
end

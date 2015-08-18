-- vstruct, the versatile struct library

-- Copyright (C) 2011 Ben "ToxicFrog" Kelly; see COPYING

local vstruct = {}
package.loaded.vstruct = vstruct

vstruct._NAME = "vstruct"
vstruct._VERSION = "2.0.0"
vstruct._M = vstruct

vstruct.cursor = require "vstruct.cursor"
local api = require "vstruct.api"
local ast = require "vstruct.ast"

local _unpack = unpack or table.unpack

-- cache control for the parser
-- true: cache is read/write (new formats will be cached, old ones retrieved)
-- false: cache is read-only
-- nil: cache is disabled
vstruct.cache = true

-- detect system endianness on startup
require "vstruct.io" ("endianness", "probe")

-- this is needed by some IO formats as well as init itself
-- FIXME: should it perhaps be a vstruct internal function rather than
-- installing it in math?
if not math.trunc then
  function math.trunc(n)
    if n < 0 then
      return math.ceil(n)
    else
      return math.floor(n)
    end
  end
end

-- turn an int into a list of booleans
-- the length of the list will be the smallest number of bits needed to
-- represent the int
function vstruct.explode(int, size)
  size = size or 0
  api.check_arg("vstruct.explode", 1, int, "number")
  api.check_arg("vstruct.explode", 2, size, "number")

  local mask = {}
  while int ~= 0 or #mask < size do
    table.insert(mask, int % 2 ~= 0)
    int = math.trunc(int/2)
  end
  return mask
end

-- turn a list of booleans into an int
-- the converse of explode
function vstruct.implode(mask, size)
  api.check_arg("vstruct.implode", 1, mask, "table")
  size = size or #mask
  api.check_arg("vstruct.implode", 2, size, "number")

  local int = 0
  for i=size,1,-1 do
    int = int*2 + ((mask[i] and 1) or 0)
  end
  return int
end

-- Given a format string, a buffer or file, and an optional third argument,
-- read data from the buffer or file according to the format string
function vstruct.read(fmt, ...)
  api.check_arg("vstruct.read", 1, fmt, "string")
  return api.compile(nil, fmt):read(...)
end

function vstruct.readvals(...)
  return _unpack(vstruct.read(...))
end

-- Given a format string, an optional file-like, and a table of data,
-- write data into the file-like (or create and return a string of packed data)
-- according to the format string
function vstruct.write(fmt, ...)
  api.check_arg("vstruct.write", 1, fmt, "string")
  return api.compile(nil, fmt):write(...)
end

-- Given a format string, compile it and return a table containing the original
-- source and the read/write functions derived from it.
function vstruct.compile(name, fmt)
  api.check_arg("vstruct.compile", 1, name, "string")
  if fmt then
    api.check_arg("vstruct.compile", 2, fmt, "string")
    return api.compile(name, fmt)
  end
  return api.compile(nil, name)
end

-- Takes the same arguments as vstruct.unpack()
-- returns an iterator over the input, repeatedly calling read until it runs
-- out of data
function vstruct.records(fmt, fd, unpacked)
  api.check_arg("vstruct.records", 1, fmt, "string")
  if unpacked ~= nil then
    api.check_arg("vstruct.records", 3, unpacked, "boolean")
  end

  local t = api.compile(nil, fmt)
  if type(fd) == "string" then
    fd = vstruct.cursor(fd)
  end

  return function()
    if fd:read(0) then
      if unpacked then
        return _unpack(t:read(fd))
      else
        return t:read(fd)
      end
    end
  end
end

-- Returns an array containing the results of vstruct.records, with an optional
-- starting index.
function vstruct.array(fmt, fd, n)
  n = n or 1
  local array = {}
  for record in vstruct.records(fmt, fd) do
    array[n] = record
    n = n+1
  end
  return array
end

return vstruct

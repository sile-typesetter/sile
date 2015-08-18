local vstruct = require "vstruct"
local cursor  = require "vstruct.cursor"
local ast = require "vstruct.ast"

local lua52 = tonumber(_VERSION:match"%d+%.%d+") >= 5.2
local loadstring = lua52 and load or loadstring
local _unpack = table.unpack or unpack

local api = {}
vstruct.registry = {}

function api.check_arg(caller, index, value, typename, check)
  if not check then
    check = function(v) return type(v) == typename end
  end

  return check(value)
      or error(string.format(
            "bad argument #%d to '%s' (%s expected, got %s)",
            index,
            caller,
            typename,
            type(value)))
end

local function is_fd(fd)
  local e,r = pcall(function()
    return fd and (fd.read or fd.write)
  end)
  return e and r
end

local function wrap_fd(fd)
  if type(fd) == "string" then
    return cursor(fd)
  end
  return fd
end

local function unwrap_fd(fd)
  if getmetatable(fd) == cursor then
    fd:flush()
    return fd.str
  end
  return fd
end

function api.read(ast, fd, data)
  fd = wrap_fd(fd)

  api.check_arg("vstruct.read", 2, fd, "file or string", is_fd)
  if data ~= nil then
    api.check_arg("vstruct.read", 3, data, "table")
  end

  return ast.ast:read(fd, data or {})
end

function api.write(ast, fd, data)
  if fd and not data then
    data,fd = fd,nil
  end
  fd = wrap_fd(fd or "")

  api.check_arg("vstruct.write", 2, fd, "file or string", is_fd)
  api.check_arg("vstruct.write", 3, data, "table")

  local result = ast.ast:write(fd, data)
  return unwrap_fd(fd)
end

local cache = {}

function api.compile(name, format)
  local obj,root

  if vstruct.cache ~= nil and cache[format] then
    obj = cache[format]
    root = obj.ast
  else
    root = ast.parse(format)
    obj = {
      source = format;
      ast = root;
      read = api.read;
      write = api.write;
    }

    if vstruct.cache == true then
      cache[format] = obj
    end
  end

  if name then
    vstruct.registry[name] = root
  end

  return obj
end

return api

-- counted strings

local io = require "vstruct.io"
local c = {}

function c.size(w)
  assert(tonumber(w), "format requires a size")
  return nil
end

function c.read(fd, _, size)
  assert(size)
  local buf = fd:read(size)
  local len = io("u", "read", nil, buf, size)
  if len == 0 then
    return ""
  end
  return fd:read(len)
end

function c.write(fd, data, size)
  return io("u", "write", nil, #data, size)
    .. io("s", "write", nil, data)
end

return c

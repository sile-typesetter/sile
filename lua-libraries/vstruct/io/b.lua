-- boolean

local io = require "vstruct.io"
local b = {}

function b.read(_, buf)
  return (buf:match("%Z") and true) or false
end

function b.readbits(bit, size)
  local n = 0
  for i=1,size do
    n = n + bit()
  end
  return n > 0
end

function b.write(_, data, size)
  return io("u", "write", nil, data and 1 or 0, size)
end

function b.writebits(bit, data, size)
  for i=1,size do
    bit(data and 1 or 0)
  end
end

return b

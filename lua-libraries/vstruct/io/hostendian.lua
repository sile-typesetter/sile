-- = set endianness to same as host system

local io = require "vstruct.io"
local he = {}

function he.hasvalue()
  return false
end

function he.size(n)
  assert(n == nil, "'=' is an endianness control, and does not have size")
  return 0
end

function he.read()
  io("endianness", "host")
end

he.write = he.read

return he

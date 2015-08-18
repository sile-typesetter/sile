-- > set endianness: big

local io = require "vstruct.io"
local be = {}

function be.hasvalue()
  return false
end

function be.size(n)
  assert(n == nil, "'>' is an endianness control, and does not have size")
  return 0
end

function be.read()
  io("endianness", "big")
end

be.write = be.read

return be

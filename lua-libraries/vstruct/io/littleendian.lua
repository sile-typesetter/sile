-- < set endianness: little

local io = require "vstruct.io"
local le = {}

function le.hasvalue()
  return false
end

function le.size(n)
  assert(n == nil, "'<' is an endianness control, and does not have size")
  return 0
end

function le.read()
  io("endianness", "little")
end

le.write = le.read

return le

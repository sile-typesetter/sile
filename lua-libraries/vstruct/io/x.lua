-- skip/pad
-- unlike the seek controls @+- or the alignment control a, x will never call
-- seek, and instead uses write '\0' or read-and-ignore - this means it is
-- safe to use on streams.

local io = require "vstruct.io"
local x = {}

function x.hasvalue()
  return false
end

function x.read(fd, buf, size)
  io("s", "read", fd, buf, size)
  return nil
end

function x.readbits(bit, size)
  for i=1,size do
    bit()
  end
end

function x.writebits(bit, _, size, val)
  val = val or 0
  assert(val == 0 or val == 1, "invalid value to `x` format in bitpack: 0 or 1 required, got "..val)
  for i=1,size do
    bit(val or 0)
  end
end

function x.write(fd, data, size, val)
  return string.rep(string.char(val or 0), size)
end

return x

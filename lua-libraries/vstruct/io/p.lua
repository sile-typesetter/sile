-- fixed point
-- format is pINTEGER_WIDTH,FRACTIONAL_WIDTH
-- sizes are in *bits* even when operating in byte mode!
-- FIXME: this should support bitpacks

local io = require "vstruct.io"
local p = {}

function p.size(size, frac)
  assert(tonumber(size), "format requires a size")
  assert(tonumber(frac), "format requires a fractional-part size")
  assert(size*8 >= frac, "fixed point number has more fractional bits than total bits")
  
  return size
end

function p.read(fd, buf, size, frac)
  return io("i", "read", fd, buf, size)/(2^frac)
end

function p.write(fd, data, size, frac)
  return io("i", "write", fd, data * 2^frac, size)
end

return p

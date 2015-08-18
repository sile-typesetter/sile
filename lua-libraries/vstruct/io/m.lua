-- bitmasks

local struct = require "vstruct"
local io   = require "vstruct.io"
local unpack = table.unpack or unpack
local m = {}

function m.read(_, buf, size)
  local mask = {}
  local e = io("endianness", "get")
  
  local sof,eof,step
  if e == "big" then
    sof,eof,step = #buf,1,-1
  else
    sof,eof,step = 1,#buf,1
  end
  
  for i=sof,eof,step do
    local byte = buf:byte(i)
    for i=1,8 do
      mask[#mask+1] = (byte % 2 == 1) and true or false
      byte = math.floor(byte/2)
    end
  end
  
  return mask
end

function m.readbits(bit, size)
  local mask = {}
  for i=1,size do
    mask[i] = bit() == 1 and true or false
  end
  return mask
end

-- bitmask
-- we use a string here because using an unsigned will lose data on bitmasks
-- wider than lua's native number format
function m.write(fd, data, size)
  local buf = ""
  local e = io("endianness", "get")
  
  for i=1,size*8,8 do
    local bits = { unpack(data, i, i+7) }
    local byte = string.char(struct.implode(bits, 8))
    if e == "big" then
      buf = byte..buf
    else
      buf = buf..byte
    end
  end
  return io("s", "write", fd, buf, size)
end

function m.writebits(bit, data, size)
  for i=1,size do
    bit(data[i] and 1 or 0)
  end
end

return m

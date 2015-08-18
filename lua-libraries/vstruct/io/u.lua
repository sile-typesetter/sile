-- unsigned ints

local io   = require "vstruct.io"
local u = {}

function u.read(_, buf)
  local n = 0
  local e = io("endianness", "get")
  
  local sof,eof,step
  if e == "big" then
    sof,eof,step = 1,#buf,1
  else
    sof,eof,step = #buf,1,-1
  end
  
  for i=sof,eof,step do
    n = n * 256 + buf:byte(i,i)
  end
  
  return n
end

function u.readbits(bit, size)
  local n = 0
  for i=1,size do
    n = n * 2 + bit()
  end
  return n
end

function u.write(_, data, size)
  local s = ""
  local e = io("endianness", "get")
  data = math.trunc(data)
  
  for i=1,size do
    if e == "big" then
      s = string.char(data % 256) .. s
    else
      s = s .. string.char(data % 256)
    end
    data = math.trunc(data/256)
  end
  
  return s
end

function u.writebits(bit, data, size)
  for i=size-1,0,-1 do
    bit(math.floor(data/2^i) % 2)
  end
end

return u

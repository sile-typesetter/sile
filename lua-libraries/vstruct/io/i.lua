-- signed integers

local io = require "vstruct.io"
local i = {}

function i.read(fd, buf, size)
  local n = io("u", "read", fd, buf, size)

  if n >= 2^(size*8-1) then
    return n - 2^(size*8)
  end
  
  return n
end

function i.readbits(bit, size)
  local n = io("u", "readbits", bit, size)
  
  if n >= 2^(size-1) then
    return n - 2^size
  end
  
  return n
end

function i.write(_, data, size)
  data = math.trunc(data)
  
  if data < 0 then
    data = data + 2^(size*8)
  end
  
  return io("u", "write", _, data, size)
end

function i.writebits(bit, data, size)
  if data < 0 then
    data = data + 2^size
  end
  
  return io("u", "writebits", bit, data, size)
end

return i

-- null-terminated strings

local io = require "vstruct.io"
local z = {}

function z.size(size, csize)
  return size
end

-- null terminated string
-- w==nil is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating

function z.write(_, data, size, csize)
  csize = csize or 1
  size = size or #data+csize
  
  assert(size % csize == 0, "string length is not a multiple of character size")
  
  -- truncate to field size
  if #data >= size then
    data = data:sub(1, size-csize)
  end
  
  return io("s", "write", _, data..("\0"):rep(csize), size)
end

-- null-terminated string
-- if w is omitted, reads up to and including the first nul, and returns everything
-- except that nul; WARNING: SLOW
-- otherwise, reads exactly w bytes and returns everything up to the first nul
function z.read(fd, buf, size, csize)
  csize = csize or 1
  nul = ("\0"):rep(csize)
  
  -- read exactly that many characters, then strip the null termination
  if size then
    local buf = io("s", "read", fd, buf, size)
    local len = 0
    
    -- search the string for the null terminator. If charsize > 1, just
    -- finding nul isn't good enough - it needs to be aligned on a character
    -- boundary.
    repeat
      len = buf:find(nul, len+1, true)
    until len == nil or (len-1) % csize == 0
    
    return buf:sub(1,(len or 0)-1)
  end
  
  -- this is where it gets ugly: the size wasn't specified, so we need to
  -- read (csize) bytes at a time looking for the null terminator
  local chars = {}
  local c = fd:read(csize)
  while c and c ~= nul do
    chars[#chars+1] = c
    c = fd:read(csize)
  end

  return table.concat(chars)
end

return z

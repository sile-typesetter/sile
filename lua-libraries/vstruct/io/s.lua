-- fixed length strings

local io = require "vstruct.io"
local s = {}

function s.size(w)
  return tonumber(w)
end

function s.read(fd, buf, size)
  if size then
    assert(#buf == size, "sanity failure: length of buffer does not match length of string format")
    return buf
  end
  
  return fd:read('*a')
end

function s.write(_, data, size)
  size = size or #data
  if size > #data then
    data = data..string.rep("\0", size - #data)
  end
  return data:sub(1,size)
end

return s

-- align-to

local io = require "vstruct.io"
local a = {}

function a.hasvalue()
  return false
end

function a.size(w)
  assert(tonumber(w), "format requires a size")
  return nil
end

function a.read(fd, _, align)
  local cur = fd:seek()
  
  if cur % align ~= 0 then
    fd:seek("cur", align - (cur % align))
  end
end

a.write = a.read

return a

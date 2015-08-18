-- @ seek to a constant offset

local seek = {}

function seek.hasvalue()
  return false
end

function seek.size(w)
  assert(tonumber(w), "format requires a size")
  return nil
end

function seek.read(fd, _, offset)
  assert(fd:seek("set", offset))
end
seek.write = seek.read

return seek

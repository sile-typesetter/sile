local Node = { size = 0 }
Node.__index = Node
Node.__call = function(self, ...)
  return self:new(...)
end

function Node:copy()
  local obj = setmetatable({}, self)
  obj.__index = obj
  return obj
end

function Node:new(...)
  local obj = self:copy()
  obj:__init(...)
  return obj
end

function Node:__init()
end

function Node:append(node)
  self[#self+1] = node
  if node.size then
    self.size = self.size + node.size
  else
    self.size = nil
  end
end

function Node:execute(env)
  for i,child in ipairs(self) do
    child:execute(env)
  end
end

function Node:read(fd, data)
  for i,child in ipairs(self) do
    child:read(fd, data)
  end
end

function Node:readbits(bits, data)
  for i,child in ipairs(self) do
    child:readbits(bits, data)
  end
end

function Node:write(fd, ctx)
  for i,child in ipairs(self) do
    child:write(fd, ctx)
  end
end

function Node:writebits(bits, ctx)
  for i,child in ipairs(self) do
    child:writebits(bits, ctx)
  end
end

return Node

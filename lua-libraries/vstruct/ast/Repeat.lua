local Node = require "vstruct.ast.Node"

local Repeat = Node:copy()

function Repeat:__init(count, child)
  self.child = child
  self.count = count
  self.size = (child.size and count * child.size) or nil
end

function Repeat:read(fd, data)
  for i=1,self.count do
    self.child:read(fd, data)
  end
end

function Repeat:readbits(bits, data)
  for i=1,self.count do
    self.child:readbits(bits, data)
  end
end

function Repeat:write(fd, data)
  for i=1,self.count do
    self.child:write(fd, data)
  end
end

function Repeat:writebits(bits, data)
  for i=1,self.count do
    self.child:writebits(bits, data)
  end
end

return Repeat

local Node = require "vstruct.ast.Node"

local Table = Node:copy()

function Table:execute(env)
  env.push()
  Node.execute(self, env)
  env.pop()
end

function Table:read(fd, data)
  local t = {}
  Node.read(self, fd, t)
  return t
end

function Table:readbits(bits, data)
  local t = {}
  Node.readbits(self, bits, t)
  return t
end 

-- We inherit write() and writebits() from Node unmodified -
-- our parent takes care of passing the right context in.

return Table

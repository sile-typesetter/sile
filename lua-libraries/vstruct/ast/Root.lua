local io = require "vstruct.io"
local Node = require "vstruct.ast.Node"

local Root = Node:copy()

function Root:__init(children)
  self[1] = children
end

function Root:read(fd, data)
  io("endianness", "host")
  self[1]:read(fd, data)
  return data
end

function Root:write(fd, data)
  io("endianness", "host")
  self[1]:write(fd, { data = data, n = 1 })
end

return Root

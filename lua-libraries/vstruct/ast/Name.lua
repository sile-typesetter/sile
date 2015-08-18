local Node = require "vstruct.ast.Node"
local Name = Node:copy()

local function put(data, key, val)
  if not key then
    data[#data+1] = val
  else
    local data = data
    for name in key:gmatch("([^%.]+)%.") do
      if data[name] == nil then
        data[name] = {}
      end
      data = data[name]
    end
    data[key:match("[^%.]+$")] = val
  end
end

local function get(ctx, key)
  local val
  if not key then
    val = ctx.data[ctx.n]
    ctx.n = ctx.n + 1
  else
    local data = ctx.data
    for name in key:gmatch("([^%.]+)%.") do
      if data[name] == nil then
        val = nil
        break
      end
      data = data[name]
    end
    val = data[key:match("[^%.]+$")]
  end

  assert(val ~= nil, "vstruct: bad input while writing: no value for key "..tostring(key or ctx.n-1))
  return { data = val, n = 1 }
end

function Name:__init(key, child)
  self.child = child
  self.size = child.size
  self.key = key
end
  
function Name:read(fd, data)
  return put(data, self.key, self.child:read(fd, data))
end

function Name:readbits(bits, data)
  return put(data, self.key, self.child:readbits(bits, data))
end

function Name:write(fd, ctx)
  self.child:write(fd, get(ctx, self.key))
end

function Name:writebits(bits, ctx)
  self.child:writebits(bits, get(ctx, self.key))
end

return Name

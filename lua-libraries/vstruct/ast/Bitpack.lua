local io = require "vstruct.io"
local Node = require "vstruct.ast.Node"
local Bitpack = Node:copy()

-- return an iterator over the individual bits in buf
local function biterator(buf)
  local e = io("endianness", "get")
  
  local data = { buf:byte(1,-1) }
  local bit = 7
  local byte = e == "big" and 1 or #data
  local delta = e == "big" and 1 or -1

  return function()    
    local v = math.floor(data[byte]/(2^bit)) % 2
    
    bit = (bit - 1) % 8
    
    if bit == 7 then -- we just wrapped around
      byte = byte + delta
    end

    return v
  end
end

local function bitpacker(buf, size)
  for i=1,size do
    buf[i] = 0
  end

  local e = io("endianness", "get")
  
  local bit = 7
  local byte = e == "big" and 1 or size
  local delta = e == "big" and 1 or -1
      
  return function(b)
    buf[byte] = buf[byte] + b * 2^bit

    bit = (bit - 1) % 8
    
    if bit == 7 then -- we just wrapped around
      byte = byte + delta
    end
  end
end

function Bitpack:__init(size)
  self.size = 0
  self.total_size = size
end

function Bitpack:finalize()
  self.size = self.size/8 -- children are getting added with size in bits, not bytes
  assert(self.size, "bitpacks cannot contain variable-width fields")
  assert(self.size == self.total_size, "bitpack contents do not match bitpack size: "..self.size.." ~= "..self.total_size)
end

function Bitpack:read(fd, data)
  local buf = fd:read(self.size)
  self:readbits(biterator(buf), data)
end

function Bitpack:write(fd, ctx)
  local buf = {}
  self:writebits(bitpacker(buf, self.size), ctx)
  fd:write(string.char(unpack(buf)))
end
  
return Bitpack

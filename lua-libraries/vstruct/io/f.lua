-- IEEE floating point floats, doubles and quads

local struct = require "vstruct"
local io   = require "vstruct.io"
local unpack = table.unpack or unpack

local sizes = {
  [4] = {1,  8, 23};
  [8] = {1, 11, 52};
  [16] = {1, 15, 112};
}

local function reader(data, size_exp, size_fraction)
  local fraction, exponent, sign
  local endian = io("endianness", "get") == "big" and ">" or "<"
  
  -- Split the unsigned integer into the 3 IEEE fields
  local bits = struct.read(endian.." m"..#data, data)[1]
  local fraction = struct.implode({unpack(bits, 1, size_fraction)}, size_fraction)
  local exponent = struct.implode({unpack(bits, size_fraction+1, size_fraction+size_exp)}, size_exp)
  local sign = bits[#bits] and -1 or 1
  
  -- special case: exponent is all 1s
  if exponent == 2^size_exp-1 then
    -- significand is 0? +- infinity
    if fraction == 0 then
      return sign * math.huge
    
    -- otherwise it's NaN
    else
      return 0/0
    end
  end
      
  -- restore the MSB of the significand, unless it's a subnormal number
  if exponent ~= 0 then
    fraction = fraction + (2 ^ size_fraction)
  else
    exponent = 1
  end
  
  -- remove the exponent bias
  exponent = exponent - 2 ^ (size_exp - 1) + 1

  -- Decrease the size of the exponent rather than make the fraction (0.5, 1]
  exponent = exponent - size_fraction
  
  return sign * math.ldexp(fraction, exponent)
end

local function writer(value, size_exp, size_fraction)
  local fraction, exponent, sign
  local size = (size_exp + size_fraction + 1)/8
  local endian = io("endianness", "get") == "big" and ">" or "<"
  local bias = 2^(size_exp-1)-1
  
  if value < 0 
  or 1/value == -math.huge then -- handle the case of -0
    sign = true
    value = -value
  else
    sign = false
  end

  -- special case: value is infinite
  if value == math.huge then
    exponent = bias+1
    fraction = 0
  
  -- special case: value is NaN
  elseif value ~= value then
    exponent = bias+1
    fraction = 2^(size_fraction-1)

  --special case: value is 0
  elseif value == 0 then
    exponent = -bias
    fraction = 0
    
  else
    fraction,exponent = math.frexp(value)
    
    -- subnormal number
    if exponent+bias <= 1 then
      fraction = fraction * 2^(size_fraction+(exponent+bias)-1)
      exponent = -bias

    else
      -- remove the most significant bit from the fraction and adjust exponent
      fraction = fraction - 0.5
      exponent = exponent - 1
      
      -- turn the fraction into an integer
      fraction = fraction * 2^(size_fraction+1)
    end
  end
  
  
  -- add the exponent bias
  exponent = exponent + bias

  local bits = struct.explode(fraction)
  local bits_exp = struct.explode(exponent)
  for i=1,size_exp do
    bits[size_fraction+i] = bits_exp[i]
  end
  bits[size_fraction+size_exp+1] = sign
  
  return struct.write(endian.."m"..size, {bits})
end

local f = {}

function f.size(n)
  n = tonumber(n)
  assert(n == 4 or n == 8 or n == 16
    , "format 'f' only supports sizes 4 (float), 8 (double) and 16 (quad)")
  
  return n
end

function f.read(_, buf, size)
  return reader(buf, unpack(sizes[size], 2))
end

function f.write(_, data, size)
  return writer(data, unpack(sizes[size], 2))
end

return f

local lpeg = require("lpeg")

local _length
_length = std.object {
  length = 0,
  stretch = 0,
  shrink = 0,
  _type = "Length",

  absolute = function (self, context)
    return _length { length = SILE.toAbsoluteMeasurement(self.length),
      stretch = SILE.toAbsoluteMeasurement(self.stretch),
      shrink = SILE.toAbsoluteMeasurement(self.shrink)
    }
  end,

  negate = function (self)
    local zero = SILE.length.new({})
    return zero - self
  end,

  fromLengthOrNumber = function (self, input)
    if type(input) == "table" then
      self.length = input.length
      self.stretch = input.stretch
      self.shrink = input.shrink
    else
      self.length = input
    end
    return self
  end,

  __tostring = function (self)
    local str = tostring(self.length).."pt"
    if self.stretch ~= 0 then str = str .. " plus "..self.stretch.."pt" end
    if self.shrink ~= 0 then str = str .. " minus "..self.shrink.."pt" end
    return str
  end,

  __add = function (self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    result = result:absolute()
    if type(other) == "table" then
      other = other:absolute()
    end

    if type(other) == "table" then
      result.length = result.length + other.length
      result.stretch = result.stretch + other.stretch
      result.shrink = result.shrink + other.shrink
    else
      result.length = result.length + other
    end
    return result
  end,

  __sub = function (self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    result = result:absolute()
    other = SILE.toAbsoluteMeasurement(other or 0)
    if type(other) == "table" then
      other = other:absolute()
    end

    if type(other) == "table" then
      result.length = result.length - other.length
      result.stretch = result.stretch - other.stretch
      result.shrink = result.shrink - other.shrink
    else
      result.length = result.length - other
    end
    return result
  end,

  __mul = function(self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    result = result:absolute()
    if type(other) == "table" then
      SU.error("Attempt to multiply two lengths together")
    else
      result.length = result.length * other
      result.stretch = result.stretch * other
      result.shrink = result.shrink * other
    end
    return result
  end,
   
  __div = function(self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    result = result:absolute()
    if type(other) == "table" then
      SU.error("Attempt to divide two lengths together")
    else
      result.length = result.length / other
      result.stretch = result.stretch / other
      result.shrink = result.shrink / other
    end
    return result
  end,

  __lt = function (self, other)
    return (self-other).length < 0
  end,

  __eq = function (self, other)
    return self.length == other.length
      and self.stretch == other.stretch
      and self.shrink == other.shrink
  end,
}

local length = {
  new = function (spec)
    return _length(spec or {})
  end,
  make = function (input)
    local result = _length {}
    result:fromLengthOrNumber(input)
    return result
  end,
  parse = function (spec)
    if not spec then return _length {} end
    if type(spec) == "table" then return _length {spec} end
    local length = lpeg.match(SILE.parserBits.length, spec)
    if not length then SU.error("Bad length definition '"..spec.."'") end
    if not length.shrink then length.shrink = 0 end
    if not length.stretch then length.stretch = 0 end
    return _length(length)
  end,

  zero = _length {}
}

return length

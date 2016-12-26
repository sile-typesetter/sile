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

  fromLengthOrNumber = function (self, x)
    if type(x) == "table" then
      self.length = x.length
      self.stretch = x.stretch
      self.shrink = x.shrink
    else
      self.length = x
    end
    return self
  end,

  __tostring = function (x)
    local s = tostring(x.length).."pt"
    if x.stretch ~= 0 then s = s .. " plus "..x.stretch.."pt" end
    if x.shrink ~= 0 then s = s .. " minus "..x.shrink.."pt" end
    return s
  end,

  __add = function (self, other)
    local result = _length {}
    result:fromLengthOrNumber(self)
    result = result:absolute()
    if type(other) == "table" then
      other = other:absolute()
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
  make = function (n)
    local result = _length {}
    result:fromLengthOrNumber(n)
    return result
  end,
  parse = function (spec)
    if not spec then return _length {} end
    if type(spec) == "table" then return _length {spec} end
    local t = lpeg.match(SILE.parserBits.length, spec)
    if not t then SU.error("Bad length definition '"..spec.."'") end
    if not t.shrink then t.shrink = 0 end
    if not t.stretch then t.stretch = 0 end
    return _length(t)
  end,

  zero = _length {}
}

return length

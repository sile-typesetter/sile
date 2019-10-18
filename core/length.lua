local lpeg = require("lpeg")

return pl.class({
    type = "Length",
    length = 0,
    stretch = 0,
    shrink = 0,

    _init = function (self, spec)
      if type(spec) == "table" then
        if spec.length then self.length = spec.length end
        if spec.stretch then self.stretch = spec.stretch end
        if spec.shrink then self.shrink = spec.shrink end
      elseif type(spec) == "number" then
        self.length = spec
      elseif type(spec) == "string" then
        local num = tonumber(spec)
        if type(num) == "number" then
          self.length = num
        else
          local parsed = lpeg.match(SILE.parserBits.length, spec)
          if not parsed then SU.error("Could not parse length '"..spec.."'") end
          self:_init(parsed)
        end
      end
    end,

    absolute = function (self)
      return SILE.length({
          length = SILE.toAbsoluteMeasurement(self.length),
          stretch = SILE.toAbsoluteMeasurement(self.stretch),
          shrink = SILE.toAbsoluteMeasurement(self.shrink)
        })
    end,

    negate = function (self)
      return self:__unm()
    end,

    new = function (spec)
      -- SU.warn("Function SILE.length.new() is deprecated, just call SILE.length(...)")
      return SILE.length(spec)
    end,

    make = function (spec)
      -- SU.warn("Function SILE.length.make() is deprecated, just call SILE.length(...)")
      return SILE.length(spec)
    end,

    parse = function (spec)
      -- SU.warn("Function SILE.length.parse() is deprecated, just call SILE.length(...)")
      return SILE.length(spec)
    end,

    fromLengthOrNumber = function (_, spec)
      -- SU.warn("Function SILE.length.fromLengthOrNumber() is deprecated, just call SILE.length(...)")
      return SILE.length(spec)
    end,

    __index = function (_, key)
      -- SU.warn("Length method " .. key .. " is deprecated, just call SILE.length(...)")
      return SILE.length()
    end,

    __tostring = function (self)
      local str = tostring(self.length).."pt"
      if self.stretch ~= 0 then str = str .. " plus "..self.stretch.."pt" end
      if self.shrink ~= 0 then str = str .. " minus "..self.shrink.."pt" end
      return str
    end,

    __add = function (self, other)
      local result = SILE.length(self):absolute()
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
      local result = SILE.length(self):absolute()
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

    __mul = function (self, other)
      local result = SILE.length(self):absolute()
      if type(other) == "table" then
        SU.error("Attempt to multiply two lengths together")
      else
        result.length = result.length * other
        result.stretch = result.stretch * other
        result.shrink = result.shrink * other
      end
      return result
    end,

    __unm = function(self)
      local zero = SILE.length()
      return zero - self
    end,

    __div = function (self, other)
      local result = SILE.length(self):absolute()
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
    end

  })

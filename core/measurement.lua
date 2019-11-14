local function _tonumber (amount)
  return SU.cast("number", amount)
end

local function _similarunit (a, b)
  if type(b) == "number" or type(a) == "number" then
    return true
  else
    return a.unit == b.unit
  end
end

local function _hardnumber (a, b)
  if type(b) == "number" or type(a) == "number" then
    return true
  else
    return false
  end
end

local function _unit (a, b)
  return type(a) == "table" and a.unit or b.unit
end

local function _amount (input)
  return type(input) == "number" and input or input.amount
end

local function _error_if_relative (a, b)
  if type(a) == "table" and a.relative or type(b) == "table" and b.relative then
    SU.error("We tried to do arithmetic on a relative measurement without explicitly absolutizing it. (That's a bug)", true)
  end
end

local measurement = pl.class({
    type = "measurement",
    amount = 0,
    unit = "pt",
    relative = false,

    _init = function (self, amount, unit)
      if unit then self.unit = unit end
      if SU.type(amount) == "length" then
        self.amount = amount.length.amount
        self.unit = amount.length.unit
      elseif type(amount) == "table" then
        self.amount = amount.amount
        self.unit = amount.unit
      elseif type(tonumber(amount)) == "number" then
        self.amount = tonumber(amount)
      elseif type(amount) == "string" then
        local parsed = SILE.parserBits.measurement:match(amount)
        if not parsed then SU.error("Could not parse measurement '"..amount.."'") end
        self.amount, self.unit = parsed.amount, parsed.unit
      end
      if not SILE.units[self.unit] then SU.error("Unknown unit: " .. unit) end
      self.relative = SILE.units[self.unit].relative
    end,

    absolute = function (self)
      local def = SILE.units[self.unit]
      local amount = def.converter and def.converter(self.amount) or self.amount * def.value
      return SILE.measurement(amount)
    end,

    tostring = function (self)
      return self:__tostring()
    end,

    tonumber = function (self)
      return self:absolute().amount
    end,

    __tostring = function (self)
      return self.amount .. self.unit
    end,

    __add = function (self, other)
      if _similarunit(self, other) then
        return SILE.measurement(_amount(self) + _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) + _tonumber(other))
      end
    end,

    __sub = function (self, other)
      if _similarunit(self, other) then
        return SILE.measurement(_amount(self) - _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) - _tonumber(other))
      end
    end,

    __mul = function (self, other)
      if _hardnumber(self, other) then
        return SILE.measurement(_amount(self) * _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) * _tonumber(other))
      end
    end,

    __pow = function (self, other)
      if _hardnumber(self, other) then
        return SILE.measurement(_amount(self) ^ _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) ^ _tonumber(other))
      end
    end,

    __div = function (self, other)
      if _hardnumber(self, other) then
        return SILE.measurement(_amount(self) / _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) / _tonumber(other))
      end
    end,

    __mod = function (self, other)
      if _hardnumber(self, other) then
        return SILE.measurement(_amount(self) % _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.measurement(_tonumber(self) % _tonumber(other))
      end
    end,

    __unm = function (self)
      local ret = SILE.measurement(self)
      ret.amount = self.amount * -1
      return ret
    end,

    __eq = function (self, other)
      return _tonumber(self) == _tonumber(other)
    end,

    __lt = function (self, other)
      return _tonumber(self) < _tonumber(other)
    end
  })


SILE.toPoints = function (factor, unit)
  -- SU.warn("Function toPoints(...) is deprecated, please use measurement(...):tonumber()")
  return measurement(factor, unit):tonumber()
end

SILE.toMeasurement = function (amount, unit)
  -- SU.warn("Please use SILE.measurement() class instead of toMeasurement function")
  return measurement(amount, unit)
end

SILE.toAbsoluteMeasurement = function (amount, unit)
  -- SU.warn("Please use SILE.measurement() class with :absolute() instead of toAbsoluteMeasurement function")
  return measurement(amount, unit):absolute()
end

return measurement

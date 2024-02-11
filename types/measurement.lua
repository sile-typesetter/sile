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

local function _pt_amount (input)
  return type(input) == "number" and input or not input and 0 or input._mutable and input.amount or input:tonumber()
end

local function _error_if_immutable (input)
  if type(input) == "table" and not input._mutable then
    SU.error("Not so fast, we can't do mutating arithmetic except on 'pt' unit measurements!", true)
  end
end

local function _error_if_relative (a, b)
  if type(a) == "table" and a.relative or type(b) == "table" and b.relative then
    SU.error("Cannot do arithmetic on a relative measurement without explicitly absolutizing it.", true)
  end
end

local measurement = pl.class({
    type = "measurement",
    amount = 0,
    unit = "pt",
    relative = false,
    _mutable = false,

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
      local _su = SILE.types.unit[self.unit]
      if not _su then SU.error("Unknown unit: " .. unit) end
      self.relative = _su.relative
      if self.unit == "pt" then self._mutable = true end
    end,

    absolute = function (self)
      return SILE.types.measurement(self:tonumber())
    end,

    tostring = function (self)
      return self:__tostring()
    end,

    tonumber = function (self)
      local def = SILE.types.unit[self.unit]
      local amount = def.converter and def.converter(self.amount) or (self.amount * def.value)
      return amount
    end,

    __tostring = function (self)
      return self.amount .. self.unit
    end,

    __concat = function (a, b)
      return tostring(a) .. tostring(b)
    end,

    __add = function (self, other)
      if _similarunit(self, other) then
        return SILE.types.measurement(_amount(self) + _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) + _tonumber(other))
      end
    end,

    -- Note all private math (_ + __func()) functions:
    -- * Are much faster than regular math operations
    -- * Are **not** intended for use outside of the most performance sensitive loops
    -- * Modify the lhs input in-place, never instantiating new objects
    -- * Always assume absolute lhs input and absolutize the rhs values at runtime
    -- * Assmue the inputs are sane with much less error checking than regular math funcs
    -- * Are not composable using chained methods since they return nil for safety
    ___add = function (self, other)
      _error_if_immutable(self)
      self.amount = self.amount + _pt_amount(other)
      return nil
    end,

    __sub = function (self, other)
      if _similarunit(self, other) then
        return SILE.types.measurement(_amount(self) - _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) - _tonumber(other))
      end
    end,

    -- See usage comments on SILE.types.measurement:___add()
    ___sub = function (self, other)
      _error_if_immutable(self)
      self.amount = self.amount - _pt_amount(other)
      return nil
    end,

    __mul = function (self, other)
      if _hardnumber(self, other) then
        return SILE.types.measurement(_amount(self) * _amount(other), _unit(self, other))
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) * _tonumber(other))
      end
    end,

    __pow = function (self, other)
      if _hardnumber(self, other) then
        return SILE.types.measurement(_amount(self) ^ _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) ^ _tonumber(other))
      end
    end,

    __div = function (self, other)
      if _hardnumber(self, other) then
        return SILE.types.measurement(_amount(self) / _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) / _tonumber(other))
      end
    end,

    __mod = function (self, other)
      if _hardnumber(self, other) then
        return SILE.types.measurement(_amount(self) % _amount(other), self.unit)
      else
        _error_if_relative(self, other)
        return SILE.types.measurement(_tonumber(self) % _tonumber(other))
      end
    end,

    __unm = function (self)
      local ret = SILE.types.measurement(self)
      ret.amount = self.amount * -1
      return ret
    end,

    __eq = function (self, other)
      return _tonumber(self) == _tonumber(other)
    end,

    __lt = function (self, other)
      return _tonumber(self) < _tonumber(other)
    end,

    __le = function (self, other)
      return _tonumber(self) <= _tonumber(other)
    end

  })

return measurement

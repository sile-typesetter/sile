local function _error_if_not_number (a)
  if type(a) ~= "number" then
    SU.error("We tried to do impossible arithmetic on a " .. SU.type(a) .. ". (That's a bug)", true)
  end
end

return pl.class({
    type = "length",
    length = SILE.measurement(0),
    stretch = SILE.measurement(0),
    shrink = SILE.measurement(0),

    _init = function (self, spec, stretch, shrink)
      if stretch or shrink then
        self.length = SILE.measurement(spec or 0)
        self.stretch = SILE.measurement(stretch or 0)
        self.shrink = SILE.measurement(shrink or 0)
      elseif type(spec) == "number" then
        self.length = SILE.measurement(spec)
      elseif SU.type(spec) == "measurement" then
        self.length = spec
      elseif type(spec) == "table" then
        self.length = SILE.measurement(spec.length or 0)
        self.stretch = SILE.measurement(spec.stretch or 0)
        self.shrink = SILE.measurement(spec.shrink or 0)
      elseif type(spec) == "string" then
        local amount = tonumber(spec)
        if type(amount) == "number" then
          self:_init(amount)
        else
          local parsed = SILE.parserBits.length:match(spec)
          if not parsed then SU.error("Could not parse length '"..spec.."'") end
          self:_init(parsed)
        end
      end
      self.stretch.amount = self.stretch.amount
      self.shrink.amount = self.shrink.amount
    end,

    absolute = function (self)
      return SILE.length(self.length:absolute(), self.stretch:absolute(), self.shrink:absolute())
    end,

    negate = function (self)
      return self:__unm()
    end,

    tostring = function (self)
      return self:__tostring()
    end,

    tonumber = function (self)
      return self.length:tonumber()
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

    __index = function (_, key) -- luacheck: ignore
      -- SU.warn("Length method " .. key .. " is deprecated, just call SILE.length(...)")
      return SILE.length()
    end,

    __tostring = function (self)
      local str = tostring(self.length)
      if self.stretch.amount ~= 0 then str = str .. " plus " .. self.stretch end
      if self.shrink.amount  ~= 0 then str = str .. " minus " .. self.shrink end
      return str
    end,

    __add = function (self, other)
      local result = SILE.length(self)
      other = SU.cast("length", other)
      result.length = result.length + other.length
      result.stretch = result.stretch + other.stretch
      result.shrink = result.shrink + other.shrink
      return result
    end,

    __sub = function (self, other)
      local result = SILE.length(self)
      other = SU.cast("length", other)
      result.length = result.length - other.length
      result.stretch = result.stretch - other.stretch
      result.shrink = result.shrink - other.shrink
      return result
    end,

    __mul = function (self, other)
      if type(self) == "number" then self, other = other, self end
      _error_if_not_number(other)
      local result = SILE.length(self)
      result.length = result.length * other
      result.stretch = result.stretch * other
      result.shrink = result.shrink * other
      return result
    end,

    __div = function (self, other)
      local result = SILE.length(self)
      _error_if_not_number(other)
      result.length = result.length / other
      result.stretch = result.stretch / other
      result.shrink = result.shrink / other
      return result
    end,

    __unm = function (self)
      local result = SILE.length(self)
      result.length = result.length:__unm()
      return result
    end,

    __lt = function (self, other)
      local a = SU.cast("length", self):absolute()
      local b = SU.cast("length", other):absolute()
      return (a - b).length < 0
    end,

    __eq = function (self, other)
      local a = SU.cast("length", self):absolute()
      local b = SU.cast("length", other):absolute()
      return a.length == b.length and a.stretch == b.stretch and a.shrink == b.shrink
    end

  })

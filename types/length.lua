--- SILE length type.
-- Lengths are composed of 3 `measurement`s: a length, a stretch, and a shrink. Each part internally is just
-- a measurement, but combined describe a flexible length that is allowed to grow up to the amout defined by stretch or
-- compress up to the amount defined by shrink.
-- @types length

local function _error_if_not_number (a)
  if type(a) ~= "number" then
    SU.error("We tried to do impossible arithmetic on a " .. SU.type(a) .. ". (That's a bug)", true)
  end
end

--- @type length
local length = pl.class()
length.type = "length"

length.length = nil
length.stretch = nil
length.shrink = nil

--- Constructor.
-- @tparam measurement spec A measurement or value that can be cast to a measurement.
-- @tparam[opt=0] measurement stretch A measurement describing how much the length is allowed to grow.
-- @tparam[opt=0] measurement shrink A measurement describing how much the length is allowed to grow.
-- @treturn length
-- @usage
-- SILE.types.length("6em", "4pt", "2pt")
-- SILE.types.length("6em plus 4pt minus 2pt")
-- SILE.types.length(30, 4, 2)
function length:_init (spec, stretch, shrink)
  if stretch or shrink then
    self.length = SILE.types.measurement(spec or 0)
    self.stretch = SILE.types.measurement(stretch or 0)
    self.shrink = SILE.types.measurement(shrink or 0)
  elseif type(spec) == "number" then
    self.length = SILE.types.measurement(spec)
  elseif SU.type(spec) == "measurement" then
    self.length = spec
  elseif SU.type(spec) == "glue" then
    self.length = SILE.types.measurement(spec.width.length or 0)
    self.stretch = SILE.types.measurement(spec.width.stretch or 0)
    self.shrink = SILE.types.measurement(spec.width.shrink or 0)
  elseif type(spec) == "table" then
    self.length = SILE.types.measurement(spec.length or 0)
    self.stretch = SILE.types.measurement(spec.stretch or 0)
    self.shrink = SILE.types.measurement(spec.shrink or 0)
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
  if not self.length then self.length = SILE.types.measurement() end
  if not self.stretch then self.stretch = SILE.types.measurement() end
  if not self.shrink then self.shrink = SILE.types.measurement() end
end

function length:absolute ()
  return SILE.types.length(self.length:tonumber(), self.stretch:tonumber(), self.shrink:tonumber())
end

function length:negate ()
  return self:__unm()
end

function length:tostring ()
  return self:__tostring()
end

function length:tonumber ()
  return self.length:tonumber()
end

function length.new (_)
  SU.deprecated("SILE.length.new", "SILE.types.length", "0.10.0")
end

function length.make (_)
  SU.deprecated("SILE.length.make", "SILE.types.length", "0.10.0")
end

function length.parse (_)
  SU.deprecated("SILE.length.parse", "SILE.types.length", "0.10.0")
end

function length.fromLengthOrNumber (_, _)
  SU.deprecated("SILE.length.fromLengthOrNumber", "SILE.types.length", "0.10.0")
end

function length.__index (_, key)
  SU.deprecated("SILE.length." .. key, "SILE.types.length", "0.10.0")
end

function length:__tostring ()
  local str = tostring(self.length)
  if self.stretch.amount ~= 0 then str = str .. " plus " .. tostring(self.stretch) end
  if self.shrink.amount  ~= 0 then str = str .. " minus " .. tostring(self.shrink) end
  return str
end

function length:__add (other)
  if type(self) == "number" then self, other = other, self end
  other = SU.cast("length", other)
  return SILE.types.length(self.length + other.length,
  self.stretch + other.stretch,
  self.shrink + other.shrink)
end

-- See usage comments on SILE.types.measurement:___add()
function length:___add (other)
  if SU.type(other) ~= "length" then
    self.length:___add(other)
  else
    self.length:___add(other.length)
    self.stretch:___add(other.stretch)
    self.shrink:___add(other.shrink)
  end
  return nil
end

function length:__sub (other)
  local result = SILE.types.length(self)
  other = SU.cast("length", other)
  result.length = result.length - other.length
  result.stretch = result.stretch - other.stretch
  result.shrink = result.shrink - other.shrink
  return result
end

-- See usage comments on SILE.types.measurement:___add()
function length:___sub (other)
  self.length:___sub(other.length)
  self.stretch:___sub(other.stretch)
  self.shrink:___sub(other.shrink)
  return nil
end

function length:__mul (other)
  if type(self) == "number" then self, other = other, self end
  _error_if_not_number(other)
  local result = SILE.types.length(self)
  result.length = result.length * other
  result.stretch = result.stretch * other
  result.shrink = result.shrink * other
  return result
end

function length:__div (other)
  local result = SILE.types.length(self)
  _error_if_not_number(other)
  result.length = result.length / other
  result.stretch = result.stretch / other
  result.shrink = result.shrink / other
  return result
end

function length:__unm ()
  local result = SILE.types.length(self)
  result.length = result.length:__unm()
  return result
end

function length:__lt (other)
  local a = SU.cast("number", self)
  local b = SU.cast("number", other)
  return a - b < 0
end

function length:__le (other)
  local a = SU.cast("number", self)
  local b = SU.cast("number", other)
  return a - b <= 0
end

function length:__eq (other)
  local a = SU.cast("length", self)
  local b = SU.cast("length", other)
  return a.length == b.length and a.stretch == b.stretch and a.shrink == b.shrink
end

return length

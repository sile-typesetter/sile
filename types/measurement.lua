--- SILE measurement type.
-- Measurements consist of an amount and a unit. Any registered `types.unit` may be used. Some units are relative and
-- their value may depend on the context where they are evaluated. Others are absolute. Unlike `types.length`
-- measurements have no stretch or shrink parameters.
-- @types measurement

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
      SU.error("Not so fast, we can't do mutating arithmetic except on 'pt' unit measurements", true)
   end
end

local function _error_if_relative (a, b)
   if type(a) == "table" and a.relative or type(b) == "table" and b.relative then
      SU.error("Cannot do arithmetic on a relative measurement without explicitly absolutizing it", true)
   end
end

--- @type measurement
local measurement = pl.class()
measurement.type = "measurement"

measurement.amount = 0
measurement.unit = "pt"
measurement.relative = false
measurement._mutable = false

--- Constructor.
-- @tparam number|length|measurement|string amount Amount of units or a string with the amount and unit.
-- @tparam[opt=pt] string unit Name of unit.
-- @treturn measurement
-- @usage
-- SILE.types.measurement(3, "em")
-- SILE.types.measurement("2%fw")
-- SILE.types.measurement(6)
function measurement:_init (amount, unit)
   if unit then
      self.unit = unit
   end
   if SU.type(amount) == "length" then
      self.amount = amount.length.amount
      self.unit = amount.length.unit
   elseif type(amount) == "table" then
      self.amount = amount.amount
      self.unit = amount.unit
   elseif type(tonumber(amount)) == "number" then
      self.amount = tonumber(amount)
   elseif type(amount) == "string" then
      local input = pl.stringx.strip(amount)
      local measurement_only_parser = SILE.parserBits.measurement * -1
      local parsed = measurement_only_parser:match(input)
      if not parsed then
         SU.error("Could not parse measurement '" .. amount .. "'")
      end
      self.amount, self.unit = parsed.amount, parsed.unit
   end
   local _su = SILE.types.unit[self.unit]
   if not _su then
      SU.error("Unknown unit: " .. unit)
   end
   self.relative = _su.relative
   if self.unit == "pt" then
      self._mutable = true
   end
end

--- Convert relative measurements to absolute values and return a measurement.
-- Resolves relative measurements (like em relevant to the current font size) into absolute measurements.
-- @treturn measurement A new measurement in pt with any relative values resolved.
-- @usage
-- > a = SILE.types.measurement("1.2em")
-- > print(a:absolute())
-- 12pt
function measurement:absolute ()
   return SILE.types.measurement(self:tonumber())
end

function measurement:tostring ()
   return self:__tostring()
end

--- Convert relative measurements to absolute values and return a number.
-- Similar to `measurement:absolute` but returns a number instead of a new measurement type.
-- @treturn number A number (corresponding to pts) for the amount with any relative values resolved.
function measurement:tonumber ()
   local def = SILE.types.unit[self.unit]
   local amount = def.converter and def.converter(self.amount) or (self.amount * def.value)
   return amount
end

function measurement:__tostring ()
   return self.amount .. self.unit
end

function measurement:__concat (other)
   return tostring(self) .. tostring(other)
end

--- Addition meta-method.
-- Assuming matching relative units or absolute units, allows two measurements to be combined into one.
-- @tparam measurement other
-- @treturn measuremnet A new measurement of the same unit type as `self` with the value of `other` added.
-- @usage
-- > a = SILE.types.measurement(6, "em")
-- > b = SILE.types.measurement("2em")
-- > c = a + b
-- > print(c)
-- 8em
function measurement:__add (other)
   if _similarunit(self, other) then
      return SILE.types.measurement(_amount(self) + _amount(other), _unit(self, other))
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) + _tonumber(other))
   end
end

-- Note all private math (_ + __func()) functions:
-- * Are much faster than regular math operations
-- * Are **not** intended for use outside of the most performance sensitive loops
-- * Modify the lhs input in-place, never instantiating new objects
-- * Always assume absolute lhs input and absolutize the rhs values at runtime
-- * Assmue the inputs are sane with much less error checking than regular math funcs
-- * Are not composable using chained methods since they return nil for safety
function measurement:___add (other)
   _error_if_immutable(self)
   self.amount = self.amount + _pt_amount(other)
   return nil
end

function measurement:__sub (other)
   if _similarunit(self, other) then
      return SILE.types.measurement(_amount(self) - _amount(other), _unit(self, other))
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) - _tonumber(other))
   end
end

-- See usage comments on SILE.types.measurement:___add()
function measurement:___sub (other)
   _error_if_immutable(self)
   self.amount = self.amount - _pt_amount(other)
   return nil
end

function measurement:__mul (other)
   if _hardnumber(self, other) then
      return SILE.types.measurement(_amount(self) * _amount(other), _unit(self, other))
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) * _tonumber(other))
   end
end

function measurement:__pow (other)
   if _hardnumber(self, other) then
      return SILE.types.measurement(_amount(self) ^ _amount(other), self.unit)
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) ^ _tonumber(other))
   end
end

function measurement:__div (other)
   if _hardnumber(self, other) then
      return SILE.types.measurement(_amount(self) / _amount(other), self.unit)
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) / _tonumber(other))
   end
end

function measurement:__mod (other)
   if _hardnumber(self, other) then
      return SILE.types.measurement(_amount(self) % _amount(other), self.unit)
   else
      _error_if_relative(self, other)
      return SILE.types.measurement(_tonumber(self) % _tonumber(other))
   end
end

function measurement:__unm ()
   local ret = SILE.types.measurement(self)
   ret.amount = self.amount * -1
   return ret
end

function measurement:__eq (other)
   return _tonumber(self) == _tonumber(other)
end

function measurement:__lt (other)
   return _tonumber(self) < _tonumber(other)
end

function measurement:__le (other)
   return _tonumber(self) <= _tonumber(other)
end

return measurement

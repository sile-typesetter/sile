local function _error_if_not_number (a)
   if type(a) ~= "number" then
      SU.error("We tried to do impossible arithmetic on a " .. SU.type(a) .. ". (That's a bug)", true)
   end
end

return pl.class({
   type = "length",
   length = nil,
   stretch = nil,
   shrink = nil,

   _init = function (self, spec, stretch, shrink)
      if stretch or shrink then
         self.length = SILE.measurement(spec or 0)
         self.stretch = SILE.measurement(stretch or 0)
         self.shrink = SILE.measurement(shrink or 0)
      elseif type(spec) == "number" then
         self.length = SILE.measurement(spec)
      elseif SU.type(spec) == "measurement" then
         self.length = spec
      elseif SU.type(spec) == "glue" then
         self.length = SILE.measurement(spec.width.length or 0)
         self.stretch = SILE.measurement(spec.width.stretch or 0)
         self.shrink = SILE.measurement(spec.width.shrink or 0)
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
            if not parsed then
               SU.error("Could not parse length '" .. spec .. "'")
            end
            self:_init(parsed)
         end
      end
      if not self.length then
         self.length = SILE.measurement()
      end
      if not self.stretch then
         self.stretch = SILE.measurement()
      end
      if not self.shrink then
         self.shrink = SILE.measurement()
      end
   end,

   absolute = function (self)
      return SILE.length(self.length:tonumber(), self.stretch:tonumber(), self.shrink:tonumber())
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

   new = function (_)
      SU.deprecated("SILE.length.new", "SILE.length", "0.10.0")
   end,

   make = function (_)
      SU.deprecated("SILE.length.make", "SILE.length", "0.10.0")
   end,

   parse = function (_)
      SU.deprecated("SILE.length.parse", "SILE.length", "0.10.0")
   end,

   fromLengthOrNumber = function (_, _)
      SU.deprecated("SILE.length.fromLengthOrNumber", "SILE.length", "0.10.0")
   end,

   __index = function (_, key)
      SU.deprecated("SILE.length." .. key, "SILE.length", "0.10.0")
   end,

   __tostring = function (self)
      local str = tostring(self.length)
      if self.stretch.amount ~= 0 then
         str = str .. " plus " .. tostring(self.stretch)
      end
      if self.shrink.amount ~= 0 then
         str = str .. " minus " .. tostring(self.shrink)
      end
      return str
   end,

   __add = function (self, other)
      if type(self) == "number" then
         self, other = other, self
      end
      other = SU.cast("length", other)
      return SILE.length(self.length + other.length, self.stretch + other.stretch, self.shrink + other.shrink)
   end,

   -- See usage comments on SILE.measurement:___add()
   ___add = function (self, other)
      if SU.type(other) ~= "length" then
         self.length:___add(other)
      else
         self.length:___add(other.length)
         self.stretch:___add(other.stretch)
         self.shrink:___add(other.shrink)
      end
      return nil
   end,

   __sub = function (self, other)
      local result = SILE.length(self)
      other = SU.cast("length", other)
      result.length = result.length - other.length
      result.stretch = result.stretch - other.stretch
      result.shrink = result.shrink - other.shrink
      return result
   end,

   -- See usage comments on SILE.measurement:___add()
   ___sub = function (self, other)
      self.length:___sub(other.length)
      self.stretch:___sub(other.stretch)
      self.shrink:___sub(other.shrink)
      return nil
   end,

   __mul = function (self, other)
      if type(self) == "number" then
         self, other = other, self
      end
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
      local a = SU.cast("number", self)
      local b = SU.cast("number", other)
      return a - b < 0
   end,

   __le = function (self, other)
      local a = SU.cast("number", self)
      local b = SU.cast("number", other)
      return a - b <= 0
   end,

   __eq = function (self, other)
      local a = SU.cast("length", self)
      local b = SU.cast("length", other)
      return a.length == b.length and a.stretch == b.stretch and a.shrink == b.shrink
   end,
})

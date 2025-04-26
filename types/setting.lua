--- SILE setting type.
-- @types setting

local setting = pl.class()
setting.type = "setting"

function setting:_init (parameter, type_, default, help, callback)
   self.parameter = parameter
   self.type = type_
   self.help = help
   self.value = nil
   self.callback = callback or function () end
   if default ~= nil then
      self:set(default, true)
   end
end

function setting:set (value, makedefault)
   value = SU.cast(self.type, value)
   self.value = value
   if makedefault then
      self:setDefault(value)
   end
   self.callback(self.value)
end

function setting:reset ()
   self.value = self.default
   self.callback(self.value)
end

function setting:setDefault (value)
   value = SU.cast(self.type, value)
   self.default = value
end

function setting:get ()
   return self.value
end

function setting:__call ()
   return self:get()
end

function setting:__tostring ()
   return self.parameter
end

return setting

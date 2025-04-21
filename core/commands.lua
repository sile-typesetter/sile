local commands = pl.class()

commands.registry = {}

function commands:register(parent, name, func, help, pack, defaults)
   if type(parent) ~= "table" then
      SU.deprecated(
         "SILE.registerCommand",
         "class:registerCommand / package:registerCommand",
         "0.14.0",
         "0.16.0",
         [[
            Commands are being scoped to the document classes or packages they are
            loaded into rather than using a global registry.
         ]]
      )
   end
   local command = SILE.types.command(parent, name, func, help, pack, defaults)
   self.registry[name] = command
end

function commands:exists(name)
   return SILE.types.command:class_of(self.registry[name])
end

function commands:get(name)
   if not self:exists(name) then
      SU.error(("No function '%s' exists"):format(name))
   end
   return self.registry[name]
end

function commands:call(name, options, content)
   return self:get(name)(options, content)
end

function commands:setDefaults (name, options)
   self:get(name):setDefaults(options)
end

function commands:dump ()
   local flag = SILE.debugFlags.commands
   SILE.debugFlags.commands = true
   for _, cmd in pairs(self.registry) do
      SU.debug("commands", cmd, "=", cmd.help)
   end
   SILE.debugFlags.commands = flag
end

return commands

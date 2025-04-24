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
   if self:exists(name) then
      SU.debug("commands", "WARNING: Redefining command", name)
   end
   local command = SILE.types.command(parent, name, func, help, pack, defaults)
   return self:_push(name, command)
end

function commands:_push (name, command)
   if not self.registry[name] then
      self.registry[name] = {}
   end
   table.insert(self.registry[name], command)
   return command
end

function commands:pop (name, count)
   if not self:exists(name) then
      SU.error("Cannot pop '%s' from the command registry, never registered."):format(name)
   end
   local stack = self.registry[name]
   local command
   count = tonumber(count) or 1
   SU.debug("commands", function () return ("Popping %d registrations of command '%s'"):format(count, name) end)
   if count <= #stack then
      for _ = 1, count do
         command = table.remove(stack)
      end
      return command
   else
      SU.error(("Cannot pop %d registrations of command '%s', only %d registered."):format(count, name, #stack))
   end
end

function commands:exists(name)
   local stack = self.registry[name]
   return stack and #stack > 0 and SILE.types.command:class_of(stack[#stack])
end

function commands:get(name, count)
   if not self:exists(name) then
      SU.error(("No function '%s' exists"):format(name))
   end
   local stack = self.registry[name]
   count = (tonumber(count) or 1) - 1
   return stack[#stack - count]
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
   for name, stack in pairs(self.registry) do
      local cmd = self:get(name)
      SU.debug("commands", name, "registered", #stack, "times", "most recently by", cmd.parent.type, cmd.parent._name, "with help =", cmd.help)
   end
   SILE.debugFlags.commands = flag
end

return commands

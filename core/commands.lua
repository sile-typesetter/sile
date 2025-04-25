local commands = pl.class()

commands.registry = {}

function commands:register (scope, name, func, help, pack, defaults)
   if type(scope) ~= "table" then
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
   local command = SILE.types.command(scope, name, func, help, pack, defaults)
   return self:_push(name, command)
end

function commands:_push (name, command)
   if not self.registry[name] then
      self.registry[name] = {}
   end
   table.insert(self.registry[name], command)
   return command, #self.registry[name]
end

function commands:pop (name, count)
   if not self:exists(name) then
      SU.error("Cannot pop '%s' from the command registry, never registered."):format(name)
   end
   local stack = self.registry[name]
   local command
   count = tonumber(count) or 1
   SU.debug("commands", function ()
      return ("Popping %d registrations of command '%s'"):format(count, name)
   end)
   if count <= #stack then
      for _ = 1, count do
         command = table.remove(stack)
      end
      return command
   else
      SU.error(("Cannot pop %d registrations of command '%s', only %d registered."):format(count, name, #stack))
   end
end

function commands:exists (name)
   local stack = self.registry[name]
   return stack and #stack > 0 and SILE.types.command:class_of(stack[#stack])
end

function commands:get (name, count)
   if not self:exists(name) then
      SU.error(("No function '%s' exists"):format(name))
   end
   local stack = self.registry[name]
   count = tonumber(count) or 1
   local index = #stack - count + 1
   return stack[index], index
end

function commands:call (name, options, content)
   return self:get(name)(options, content)
end

function commands:setDefaults (name, options)
   self:get(name):setDefaults(options)
end

function commands:pushWrapper (scope, name, func, defaults)
   local original = self:get(name)
   local command = SILE.types.command(scope, name, function (options, content)
      return func(options, content, original)
   end, original._help, original.pack, defaults)
   return self:_push(name, command)
end

function commands:dump ()
   local flag = SILE.debugFlags.commands
   SILE.debugFlags.commands = true
   for name, stack in pairs(self.registry) do
      local cmd = self:get(name)
      SU.debug(
         "commands",
         name,
         "registered",
         #stack,
         "times",
         "most recently by",
         cmd.scope.type,
         cmd.scope._name,
         "with help =",
         cmd._help
      )
   end
   SILE.debugFlags.commands = flag
end

function commands:env (scope)
   local global_or_command_from_registry = {}
   if not SILE.scratch.docvars then
      SILE.scratch.docvars = {}
   end
   setmetatable(global_or_command_from_registry, {
      __index = function (_, key)
         if SILE.scratch.docvars[key] then
            return SILE.scratch.docvars[key]
         elseif self:exists(key) then
            return self:get(key)
         elseif scope and scope[key] then
            if type(scope[key]) == "function" then
               return function (...)
                  return scope[key](scope, ...)
               end
            end
            return scope[key]
         elseif SILE[key] then
            return SILE[key]
         else
            return _G[key]
         end
      end,
      __newindex = function (_, key, val)
         SILE.scratch.docvars[key] = val
      end,
   })
   return global_or_command_from_registry
end

return commands

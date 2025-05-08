--- core command registry instance
--- @module SILE.commands

--- @type commands
local registry = require("types.registry")
local commands = pl.class(registry)
commands._name = "commands"

function commands:_init ()
   registry._init(self)
end

function commands:register (parent, name, func, help, pack, defaults)
   if self:exists(parent, name) then
      SU.debug("commands", "WARNING: Redefining command", name)
   else
      self._registry[name] = {}
   end
   local command = SILE.types.command(name, func, help, pack, defaults)
   return self:push(parent, command)
end

function commands:call (parent, name, options, content)
   return self:pull(parent, name)(options, content)
end

function commands:setDefaults (parent, name, options)
   self:pull(parent, name):setDefaults(options)
end

function commands:pushWrapper (parent, name, func, defaults)
   local original = self:pull(parent, name)
   local command = SILE.types.command(name, function (options, content)
      return func(options, content, original)
   end, original.help, original.pack, defaults)
   return self:push(parent, command)
end

function commands:dump (parent)
   local flag = SILE.debugFlags.commands
   SILE.debugFlags.commands = true
   for name, stack in pairs(self._registry) do
      local cmd = self:pull(parent, name)
      SU.debug(
         "commands",
         name,
         "registered",
         #stack,
         "times",
         "most recently by",
         cmd.parent.type,
         cmd.parent._name,
         "with help =",
         cmd.help
      )
   end
   SILE.debugFlags.commands = flag
end

return commands

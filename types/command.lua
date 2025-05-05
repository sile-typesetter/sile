--- SILE command type
-- @types command

local command = pl.class()
command.type = "command"

function command:_init (name, func, help, pack, defaults)
   self.name = name
   self.func = func
   self.help = help
   if not pack then
      local where = debug.getinfo(2).source
      pack = where:match("(%w+).lua")
   end
   self.pack = pack
   self.defaults = defaults or {}
end

function command:__call (options, content)
   content = content or {}
   if SILE.traceback and type(content) == "table" and not content.lno then
      -- This call is from code (no content.lno) and we want to spend the time
      -- to determine everything we need about the caller
      local caller = debug.getinfo(2, "Sl")
      content.file, content.lno = caller.short_src, caller.currentline
   end
   options = options or {}
   local pId = SILE.traceStack:pushCommand(self.name, content, options)
   for k, v in pairs(self.defaults) do
      if not options[k] then
         options[k] = v
      end
   end
   local result = self.func(options, content)
   SILE.traceStack:pop(pId)
   return result
end

function command:__tostring ()
   return self.name
end

function command:setDefaults (options)
   self.defaults = options
end

return command

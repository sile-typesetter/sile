local repl = {}

local _repl

function repl.initRepl ()
   _repl = require("repl.console")
   local has_linenoise, linenoise = pcall(require, "linenoise")
   if has_linenoise then
      _repl:loadplugin("linenoise")
      linenoise.enableutf8()
   else
      -- XXX check that we're not receiving input from a non-tty
      local has_rlwrap = os.execute("which rlwrap >/dev/null 2>/dev/null") == 0
      if has_rlwrap and not os.getenv("LUA_REPL_RLWRAP") then
         local command = "LUA_REPL_RLWRAP=1 rlwrap"
         local index = 0
         while arg[index - 1] do
            index = index - 1
         end
         while arg[index] do
            command = string.format("%s %q", command, arg[index])
            index = index + 1
         end
         os.execute(command)
         return
      end
   end
   _repl:loadplugin("history")
   _repl:loadplugin("completion")
   _repl:loadplugin("autoreturn")
   _repl:loadplugin("rcfile")
   _repl.getcontext = function ()
      return SILE.commands:env()
   end
end

function repl:enter ()
   if not _repl then
      self.initRepl()
   end
   _repl:run()
end

return repl

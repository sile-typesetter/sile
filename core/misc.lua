-- TODO: this probably needs deprecating, moved here just to get out of the way so
-- typesetters classing works as expected
local function typesetNaturally (frame, func)
   local saveTypesetter = SILE.typesetter
   if SILE.typesetter.frame then
      SILE.typesetter.frame:leave(SILE.typesetter)
   end
   SILE.typesetter = SILE.typesetters.default(frame)
   SILE.settings:temporarily(func)
   SILE.typesetter:leaveHmode()
   SILE.typesetter:chuck()
   SILE.typesetter.frame:leave(SILE.typesetter)
   SILE.typesetter = saveTypesetter
   if SILE.typesetter.frame then
      SILE.typesetter.frame:enter(SILE.typesetter)
   end
end

local function call (command, options, content)
   -- We used to set a global default typesetter all the time, now the class handling firing one up for itself. This
   -- leaves library usage (outside of our CLI) and some of our unit tests a bit out in the cold.
   if not SILE.typesetter then
      SU.deprecated("SILE.init()", "SILE.init(); SILE.typesetter = SILE.typesetters.default()", "0.16.0", "0.17.0")
      SILE.typesetter = SILE.typesetters.default()
   end
   options = options or {}
   content = content or {}
   if SILE.traceback and type(content) == "table" and not content.lno then
      -- This call is from code (no content.lno) and we want to spend the time
      -- to determine everything we need about the caller
      local caller = debug.getinfo(2, "Sl")
      content.file, content.lno = caller.short_src, caller.currentline
   end
   local pId = SILE.traceStack:pushCommand(command, content, options)
   if not SILE.Commands[command] then
      SU.error("Unknown command " .. command)
   end
   local result = SILE.Commands[command](options, content)
   SILE.traceStack:pop(pId)
   return result
end

local function registerCommand (parent, name, func, help, pack)
   if not parent then
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
   SILE.Commands[name] = func
   if not pack then
      local where = debug.getinfo(2).source
      pack = where:match("(%w+).lua")
   end
   --if not help and not pack:match(".sil") then SU.error("Could not define command '"..name.."' (in package "..pack..") - no help text" ) end
   SILE.Help[name] = {
      description = help,
      where = pack,
   }
end

local function setCommandDefaults (command, options)
   local oldCommand = SILE.Commands[command]
   SILE.Commands[command] = function (defaults, content)
      for k, v in pairs(options) do
         defaults[k] = defaults[k] or v
      end
      return oldCommand(defaults, content)
   end
end

-- TODO: Move to new table entry handler in types.unit
local function registerUnit (unit, spec)
   -- If a unit exists already, clear it first so we get fresh meta table entries, see #1607
   if SILE.types.unit[unit] then
      SILE.types.unit[unit] = nil
   end
   SILE.types.unit[unit] = spec
end

local function paperSizeParser (size)
   SU.deprecated("SILE.paperSizeParser", "SILE.papersize", "0.15.0", "0.16.0")
   return SILE.papersize(size)
end

return {
   typesetNaturally = typesetNaturally,
   call = call,
   registerCommand = registerCommand,
   setCommandDefaults = setCommandDefaults,
   registerUnit = registerUnit,
   paperSizeParser = paperSizeParser,
}

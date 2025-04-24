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

local function call (name, options, content)
   -- We used to set a global default typesetter all the time, now the class handling firing one up for itself. This
   -- leaves library usage (outside of our CLI) and some of our unit tests a bit out in the cold.
   if not SILE.typesetter then
      SU.deprecated("SILE.init()", "SILE.init(); SILE.typesetter = SILE.typesetters.default()", "0.16.0", "0.17.0")
      SILE.typesetter = SILE.typesetters.default()
   end
   return SILE.commands:call(name, options, content)
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
   registerUnit = registerUnit,
   paperSizeParser = paperSizeParser,
}

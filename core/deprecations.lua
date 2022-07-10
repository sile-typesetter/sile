local nostd = function ()
  SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0", [[
  Lua stdlib (std.*) is no longer provided by SILE, you may use
      local std = require("std")
  in your project directly if needed. Note you may need to install the Lua
  rock as well since it no longer ships as a dependency.]])
end
-- luacheck: push ignore std
std = setmetatable({}, {
  __call = nostd,
  __index = nostd
})
-- luacheck: pop

local fluentglobal = function ()
  SU.deprecated("SILE.fluent", "fluent", "0.14.0", "0.15.0", [[
  The SILE.fluent object was never more than just an instance of a
  third party library with no relation the scope of the SILE object.
  This was even confusing me and marking it awkward to work on
  SILE-as-a-library. Making it a provided global clarifies whot it
  is and is not. Maybe someday we'll actually make a wrapper that
  tracks the state of the document language.]])
end
SILE.fluent = setmetatable({}, {
  __call = fluentglobal,
  __index = fluentglobal,
})

local nobaseclass = function ()
  SU.deprecated("SILE.baseclass", "SILE.classes.base", "0.13.0", "0.14.0", [[
  The inheritance system for SILE classes has been refactored using a different
  object model.]])
end
SILE.baseClass = setmetatable({}, {
    __call = nobaseclass,
    __index = nobaseclass
  })

SILE.toPoints = function (_, _)
  SU.deprecated("SILE.toPoints", "SILE.measurement():tonumber", "0.10.0", "0.13.1")
end

SILE.toMeasurement = function (_, _)
  SU.deprecated("SILE.toMeasurement", "SILE.measurement", "0.10.0", "0.13.1")
end

SILE.toAbsoluteMeasurement = function (_, _)
  SU.deprecated("SILE.toAbsoluteMeasurement", "SILE.measurement():absolute", "0.10.0", "0.13.1")
end

SILE.readFile = function (filename)
  SU.deprecated("SILE.readFile", "SILE.processFile", "0.14.0", "0.16.0")
  return SILE.processFile(filename)
end

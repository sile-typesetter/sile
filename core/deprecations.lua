local nostd = function ()
  SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0", [[
  Lua stdlib (std.*) is no longer provided by SILE, you may use
      local std = require("std")
  in your project directly if needed. Note you may need to install the Lua
  rock as well since it no longer ships as a dependency.]])
end
-- luacheck: push ignore std
---@diagnostic disable: lowercase-global
std = setmetatable({}, {
  __call = nostd,
  __index = nostd
})
-- luacheck: pop
---@diagnostic enable: lowercase-global

local fluent_once = false
local fluentglobal = function ()
  if fluent_once then return end
  SU.deprecated("SILE.fluent", "fluent", "0.14.0", "0.15.0", [[
  The SILE.fluent object was never more than just an instance of a
  third party library with no relation the scope of the SILE object.
  This was even confusing me and marking it awkward to work on
  SILE-as-a-library. Making it a provided global clarifies whot it
  is and is not. Maybe someday we'll actually make a wrapper that
  tracks the state of the document language.]])
  fluent_once = true
end
SILE.fluent = setmetatable({}, {
  __call = function (_, ...)
    fluentglobal()
    SILE.fluent = fluent
    return fluent(pl.utils.unpack({...}, 1, select("#", ...)))
  end,
  __index = function (_, key)
    fluentglobal()
    SILE.fluent = fluent
    return fluent[key]
  end
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

SILE.defaultTypesetter = function ()
  SU.deprecated("SILE.defaultTypesetter", "SILE.typesetters.base", "0.14.6", "0.15.0")
end

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

SILE.colorparser = function (input)
  SU.deprecated("SILE.colorparser", "SILE.color", "0.14.0", "0.16.0",
    [[Color results are now color objects, not just tables with relevant values.]])
  return SILE.color(input)
end

function SILE.doTexlike (doc)
  SU.deprecated("SILE.doTexlike", "SILE.processString", "0.14.0", "0.16.0",
    [[Add format argument "sil" to skip content detection and assume SIL input]])
  return SILE.processString(doc, "sil")
end

local nopackagemanager = function ()
  SU.deprecated("SILE.PackageManager", nil, "0.13.2", "0.15.0", [[
  The built in SILE package manager has been completely deprecated. In its place
    SILE can now load classes, packages, and other resources installed via
    LuaRocks. Any SILE package may be published on LuaRocks.org or any private
    repository. Rocks may be installed to the host system root filesystem, a user
    directory, or a custom location. Please see the SILE manual for usage
    instructions. Package authors especially can review the template repository
    on GitHub for how to create a package.
  ]])
end

SILE.PackageManager = {}
setmetatable(SILE.PackageManager, {
  __index = nopackagemanager
})

-- luacheck: ignore updatePackage
-- luacheck: ignore installPackage
updatePackage = nopackagemanager
installPackage = nopackagemanager

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

SILE.defaultTypesetter = function ()
  SU.deprecated("SILE.defaultTypesetter", "SILE.typesetters.base", "0.14.6", "0.15.0")
end

SILE.toPoints = function (_, _)
  SU.deprecated("SILE.toPoints", "SILE.types.measurement():tonumber", "0.10.0", "0.13.1")
end

SILE.toMeasurement = function (_, _)
  SU.deprecated("SILE.toMeasurement", "SILE.types.measurement", "0.10.0", "0.13.1")
end

SILE.toAbsoluteMeasurement = function (_, _)
  SU.deprecated("SILE.toAbsoluteMeasurement", "SILE.types.measurement():absolute", "0.10.0", "0.13.1")
end

SILE.readFile = function (filename)
  SU.deprecated("SILE.readFile", "SILE.processFile", "0.14.0", "0.16.0")
  return SILE.processFile(filename)
end

local usetypes = function (type)
  SU.deprecated(("SILE.%s"):format(type), ("SILE.types.%s"):format(type), "0.15.0", "0.16.0", ([[
  In order to keep things tidy internally, more easily allow 3rd party
  packages to override core functions, and substitute some slow bits
  with Rust modules, internal types have been moved from the top level
  SILE global to a types namespace.

  Please substitute 'SILE.%s()' with 'SILE.types.%s()'.
  ]]):format(type, type))
  return SILE.types[type]
end

SILE.color = setmetatable({}, {
    __call = function (_, ...) return usetypes("color")(...) end,
    __index = function () return usetypes("color") end,
  })

SILE.measurement = setmetatable({}, {
    __call = function (_, ...) return usetypes("measurement")(...) end,
    __index = function () return usetypes("measurement") end,
  })

SILE.length = setmetatable({}, {
    __call = function (_, ...) return usetypes("length")(...) end,
    __index = function () return usetypes("length") end,
  })

local usetypes2 = function (old, new, type)
  SU.deprecated(("SILE.%s.%s"):format(old, type), ("SILE.types.%s.%s"):format(new, type), "0.15.0", "0.16.0", ([[
  In order to keep things tidy internally, more easily allow 3rd party
  packages to override core functions, and substitute some slow bits
  with Rust modules, internal types have been moved from the top level
  SILE global to a types namespace.

  Please substitute 'SILE.%s.%s()' with 'SILE.types.%s.%s()'.
  ]]):format(old, type, new, type))
  return SILE.types[new][type]
end

SILE.nodefactory = setmetatable({}, {
    __index = function (_, type) return usetypes2("nodefactory", "node", type) end,
  })

SILE.units = setmetatable({}, {
    __index = function (_, type) return usetypes2("units", "unit", type) end,
  })

SILE.colorparser = function (input)
  SU.deprecated("SILE.colorparser", "SILE.types.color", "0.14.0", "0.16.0",
    [[Color results are now color objects, not just tables with relevant values.]])
  return SILE.types.color(input)
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

SU.utf8char = function ()
  SU.deprecated("SU.utf8char", "luautf8.char", "0.11.0", "0.12.0")
end

SU.utf8codes = function ()
  SU.deprecated("SU.utf8codes", "luautf8.codes", "0.11.0", "0.12.0")
end

-- luacheck: ignore updatePackage
-- luacheck: ignore installPackage
updatePackage = nopackagemanager
installPackage = nopackagemanager

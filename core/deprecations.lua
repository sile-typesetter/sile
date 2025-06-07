local fluent_once = false
local fluentglobal = function ()
   if fluent_once then
      return
   end
   SU.deprecated(
      "SILE.fluent",
      "fluent",
      "0.14.0",
      "0.15.0",
      [[
         The SILE.fluent object was never more than just an instance of a third party
         library with no relation the scope of the SILE object. This was even confusing
         me and marking it awkward to work on SILE-as-a-library. Making it a provided
         global clarifies whot it is and is not. Maybe someday we'll actually make a
         wrapper that tracks the state of the document language.
      ]]
   )
   fluent_once = true
end
SILE.fluent = setmetatable({}, {
   __call = fluentglobal,
   __index = fluentglobal,
})

SILE.defaultTypesetter = function ()
   SU.deprecated("SILE.defaultTypesetter", "SILE.typesetters.base", "0.14.6", "0.15.0")
end

SILE.readFile = function ()
   SU.deprecated("SILE.readFile", "SILE.processFile", "0.14.0", "0.16.0")
end

local usetypes = function (type)
   SU.deprecated(
      ("SILE.%s"):format(type),
      ("SILE.types.%s"):format(type),
      "0.15.0",
      "0.16.0",
      ([[
         In order to keep things tidy internally, more easily allow 3rd party packages
         to override core functions, and substitute some slow bits with Rust modules,
         internal types have been moved from the top level SILE global to a types
         namespace.

         Please substitute 'SILE.%s()' with 'SILE.types.%s()'.
      ]]):format(type, type)
   )
end

SILE.color = setmetatable({}, {
   __call = function (_, ...)
      return usetypes("color")(...)
   end,
   __index = function ()
      return usetypes("color")
   end,
})

SILE.measurement = setmetatable({}, {
   __call = function (_, ...)
      return usetypes("measurement")(...)
   end,
   __index = function ()
      return usetypes("measurement")
   end,
})

SILE.length = setmetatable({}, {
   __call = function (_, ...)
      return usetypes("length")(...)
   end,
   __index = function ()
      return usetypes("length")
   end,
})

local usetypes2 = function (old, new, type)
   SU.deprecated(
      ("SILE.%s.%s"):format(old, type),
      ("SILE.types.%s.%s"):format(new, type),
      "0.15.0",
      "0.16.0",
      ([[
         In order to keep things tidy internally, more easily allow 3rd party packages
         to override core functions, and substitute some slow bits with Rust modules,
         internal types have been moved from the top level SILE global to a types
         namespace.

         Please substitute 'SILE.%s.%s()' with 'SILE.types.%s.%s()'.
      ]]):format(old, type, new, type)
   )
end

SILE.nodefactory = setmetatable({}, {
   __index = function (_, type)
      return usetypes2("nodefactory", "node", type)
   end,
})

SILE.units = setmetatable({}, {
   __index = function (_, type)
      return usetypes2("units", "unit", type)
   end,
})

SILE.colorparser = function ()
   SU.deprecated(
      "SILE.colorparser",
      "SILE.types.color",
      "0.14.0",
      "0.16.0",
      [[Color results are now color objects, not just tables with relevant values.]]
   )
end

function SILE.doTexlike ()
   SU.deprecated(
      "SILE.doTexlike",
      "SILE.processString",
      "0.14.0",
      "0.16.0",
      [[Add format argument "sil" to skip content detection and assume SIL input.]]
   )
end

local nopackagemanager = function ()
   SU.deprecated(
      "SILE.PackageManager",
      nil,
      "0.13.2",
      "0.15.0",
      [[
         The built in SILE package manager has been completely deprecated. In its place
         SILE can now load classes, packages, and other resources installed via
         LuaRocks. Any SILE package may be published on LuaRocks.org or any private
         repository. Rocks may be installed to the host system root filesystem, a user
         directory, or a custom location. Please see the SILE manual for usage
         instructions. Package authors especially can review the template repository
         on GitHub for how to create a package.
      ]]
   )
end

SILE.PackageManager = {}
setmetatable(SILE.PackageManager, {
   __index = nopackagemanager,
})

function SILE.paperSizeParser ()
   SU.deprecated("SILE.paperSizeParser", "SILE.papersize", "0.15.0", "0.16.0")
end

local nolanguageloader = function (_, key)
   if key == "loadLanguage" then
      return function (language)
         SU.deprecated("SILE.languageSupport.<code>", ('require("languages.%s")'):format(language), "0.16.0", "0.17.0")
         return SILE.languages[language]
      end
   end
end

SILE.languageSupport = {}
setmetatable(SILE.languageSupport, {
   __index = nolanguageloader,
})

local nonodemakers = function (_, key)
   return function ()
      SU.deprecated(
         "SILE.nodeMakers.<code>",
         ('SILE.typesetter:_cacheLanguage("%s").nodemaker'):format(key),
         "0.16.0",
         "0.17.0"
      )
      return SILE.typesetter:_cacheLanguage(key).nodemaker
   end
end

SILE.nodeMakers = {}
setmetatable(SILE.nodeMakers, {
   __index = nonodemakers,
})

SILE.tokenizers = {}
setmetatable(SILE.tokenizers, {
   __index = nonodemakers,
})

SILE.showHyphenationPoints = function (...)
   SU.deprecated(
      "SILE.showHyphenationPoints",
      "SILE.typesetter.language.hyphenator:showHyphenationPoints",
      "0.16.0",
      "0.17.0"
   )
   local language = SILE.typesetter.language
   return language.hyphenator:showHyphenationPoints(...)
end

local function nocommands ()
   SU.deprecated(
      "SILE.Commands",
      "SILE.commands",
      "0.16.0",
      "0.17.0",
      [[
         Direct access to the Commands table has been deprecataed. Please use the command registry instead. There is
         temporarily) a global `SILE.commands` available, but most command registry functions are available through the
         module interface. Classes and packages and such can register their own functions using the local interfaces.
      ]]
   )
end

SILE.Commands = {}
setmetatable(SILE.Commands, {
   __index = function (_, name)
      nocommands()
      -- Return the bare function for legacy use since a table type would be unexpected
      return SILE.commands:pull(name).func
   end,
   __newindex = function (_, name, func)
      nocommands()
      return SILE.commands:register(name, func)
   end,
})

SILE.registerCommand = function (name, func, help, pack)
   nocommands()
   return SILE.commands:register(name, func, help, pack)
end

local function nohelp ()
   SU.deprecated(
      "SILE.Commands",
      "SILE.commands",
      "0.16.0",
      "0.17.0",
      [[
         Direct access to the Help table has been deprecataed. Please use the
      ]]
   )
end

SILE.Help = {}
setmetatable(SILE.Help, {
   __index = function (_, name)
      nohelp()
      local command = SILE.commands:pull(name)
      return {
         description = command.help,
      }
   end,
   __newindex = function (_, name, spec)
      local command = SILE.commands:pull(name)
      command.help = spec.description
   end,
})

SILE.setCommandDefaults = function (command, options)
   SU.deprecated("SILE.setCommandDefaults", "SILE.commands.setDefaults", "0.16.0", "0.17.0")
   return SILE.commands:setDefaults(command, options)
end

SILE.linebreak = {}
setmetatable(SILE.linebreak, {
   __index = function (_, key)
      SU.deprecated("SILE.linebreak:*", "typesetter.linebreaker:*", "0.16.0", "0.17.0")
      return SILE.linebreakers.default[key]
   end,
})

SILE.pagebuilder = {}
setmetatable(SILE.pagebuilder, {
   __index = function (_, key)
      SU.deprecated("SILE.pagebuilder:*", "typesetter.pagebuilder:*", "0.16.0", "0.17.0")
      return SILE.linebreakers.default[key]
   end,
})

SILE.fontManager = {}
setmetatable(SILE.fontManager, {
   __index = function (_, key)
      SU.deprecated("SILE.fontManager:*", "SILE.fontmanager:*", "0.16.0", "0.17.0")
      return SILE.fontmanager[key]
   end,
})

SILE.newFrame = function (spec, prototype)
   SU.deprecated("SILE.newFrame", "<module>:frames:new", "0.16.0", "0.17.0")
   return SILE.frames:new(spec, prototype)
end

SILE.getFrame = function (id)
   SU.deprecated("SILE.getFrame", "class.frames:pull", "0.16.0", "0.17.0")
   return SILE.frames:pull(id)
end

SILE.parseComplexFrameDimension = function (dimension)
   SU.deprecated("SILE.parseComplexFrameDimension", "module.frames:parseComplexFrameDimension", "0.16.0", "0.17.0")
   return SILE.frames:parseComplexFrameDimension(dimension)
end

-- luacheck: ignore updatePackage
-- luacheck: ignore installPackage
updatePackage = nopackagemanager
installPackage = nopackagemanager

local function deprecations_post ()
   local the_actual_frame_registry = SILE.frames
   SILE.frames = nil

   local mt = getmetatable(SILE)

   function mt:__index (key)
      if key == "frames" then
         SU.deprecated("SILE.frames[]", "<module>.frames", "0.16.0", "0.17.0")
         return the_actual_frame_registry
      elseif key == "framePrototype" then
         SU.deprecated("SILE.framePrototype", "SILE.types.frame", "0.16.0", "0.17.0")
         return SILE.types.frame
      end
      return rawget(SILE, key)
   end

   function mt:__newindex (key, value)
      if key == "frames" then
         SU.warn("Implement frameset redo")
         the_actual_frame_registry._registry = value
         for _, v in pairs(value) do
            SU.deprecated("SILE.frames[]", "<module>.frames:new()", "0.16.0", "0.17.0")
            the_actual_frame_registry:new(v)
         end
      end
      return rawset(self, key, value)
   end

   setmetatable(SILE.documentState, {
      __index = function (self, key)
         if key == "thisPageTemplate" then
            SU.deprecated("SILE.documentState.thisPageTemplate", "class.frames", "0.16.0", "0.17.0")
            return { frames = SILE.frames }
         end
         return rawget(self, key)
      end,
   })
end

return deprecations_post

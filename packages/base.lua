--- SILE package class.
-- @interfaces packages

local package = pl.class()
package.type = "package"
package._name = "base"

package._initialized = false
package.class = nil

-- For shimming packages that used to have legacy exports
package.exports = {}

local function script_path ()
   local src = debug.getinfo(3, "S").source:sub(2)
   local base = src:match("(.*[/\\])")
   return base
end

local settingDeclarations = {}
local rawhandlerRegistrations = {}
local commandRegistrations = {}

function package:_init (_, reload)
   self.class = SILE.scratch.half_initialized_class or SILE.documentState.documentClass
   if not self.class then
      SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
   end
   self.basedir = script_path()
   -- Note string.format(%p) would be nicer than tostring() but only LuaJIT and Lua 5.4 support it
   local settingsDeclarator = tostring(self.declareSettings)
   if reload or not settingDeclarations[settingsDeclarator] then
      settingDeclarations[settingsDeclarator] = true
      self:declareSettings()
   end
   local rawhandlerRegistrator = tostring(self.registerRawHandlers)
   if reload or not rawhandlerRegistrations[rawhandlerRegistrator] then
      rawhandlerRegistrations[rawhandlerRegistrator] = true
      self:registerRawHandlers()
   end
   local commandRegistrator = tostring(self.registerCommands)
   if reload or not commandRegistrations[commandRegistrator] then
      commandRegistrations[commandRegistrator] = true
      self:registerCommands()
   end
end

function package:_post_init ()
   self._initialized = true
end

function package.declareSettings (_) end

function package.registerRawHandlers (_) end

function package:loadPackage (packname, options, reload)
   return self.class:loadPackage(packname, options, reload)
end

function package:reloadPackage (packname, options)
   return self.class:reloadPackage(packname, options)
end

function package.registerCommands (_) end

-- This gives us a hook to match commands with the packages that registered
-- them as opposed to core commands or class-provided commands

--- Register a function as a SILE command.
-- Takes any Lua function and registers it for use as a SILE command (which will in turn be used to process any content
-- nodes identified with the command name.
--
-- A similar method is available for classes, `classes:registerCommand`.
-- @tparam string name Name of cammand to register.
-- @tparam function func Callback function to use as command handler.
-- @tparam[opt] nil|string help User friendly short usage string for use in error messages, documentation, etc.
-- @tparam[opt] nil|string pack Information identifying the module registering the command for use in error and usage
-- messages. Usually auto-detected.
-- @see SILE.classes:registerCommand
function package:registerCommand (name, func, help, pack)
   self.class:registerCommand(name, func, help, pack)
end
function package:registerRawHandler (format, callback)
   self.class:registerRawHandler(format, callback)
end

-- Using this rather than doing the work directly will give us a way to
-- un-export them if we ever need to unload modules and revert functions
function package:export (name, func)
   self.class[name] = func
end

-- Shims for two possible kinds of legacy exports: blind direct stuffing into
-- the class but not expecting to be called as a method AND the exports table
-- to package modules...

local _deprecate_class_funcs = [[
  Please explicitly use functions provided by packages by referencing
  them in the document class's list of loaded packages rather than the
  legacy solution that added non-method functions to the class.]]

local _deprecate_exports_table = [[
  Please explicitly use functions provided by packages by referencing
  them in the document class's list of loaded packages rather than the
  legacy solution of calling them from an exports table.]]

function package:deprecatedExport (name, _, noclass, notable)
   if not noclass then
      self.class[name] = function ()
         SU.deprecated(
            ("class.%s"):format(name),
            ("class.packages.%s:%s"):format(self._name, name),
            "0.14.0",
            "0.16.0",
            _deprecate_class_funcs
         )
      end
   end

   if not notable then
      self.exports[name] = function ()
         SU.deprecated(
            ("require('packages.%s').exports.%s"):format(self._name, name),
            ("class.packages.%s:%s"):format(self._name, name),
            "0.14.0",
            "0.16.0",
            _deprecate_exports_table
         )
      end
   end
end

return package

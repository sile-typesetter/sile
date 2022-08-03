local package = pl.class()
package.type = "package"
package._name = "base"

package._initialized = false
package.class = nil

-- For shimming packages that used to have legacy exports
package.exports = {}

function package:_init (_)
  self.class = SILE.documentState.documentClass or SILE.scratch.half_initialized_class
  if not self.class then
    SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
  end
  self:declareSettings()
  self:registerRawHandlers()
  self:registerCommands()
end

function package:_post_init ()
  self._initialized = true
end

function package.declareSettings (_) end

function package.registerRawHandlers (_) end

function package.registerCommands (_) end

-- This gives us a hook to match commands with the packages that registered
-- them as opposed to core commands or class-provided commands
function package:registerCommand (name, func, help, pack)
  self.class:registerCommand(name, func, help, pack)
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

function package:deprecatedExport (name, func, noclass, notable)

  if not noclass then
    self.class[name] = function (...)
      -- http://lua-users.org/wiki/VarargTheSecondClassCitizen
      local inputs = {...}
      -- local inputs = table.unpack({...}, 1, select("#", ...))
      if type(inputs[1]) ~= "table" or inputs[1].type ~= "class" then
        table.insert(inputs, 1, self.class)
      end
      SU.deprecated(("class.%s"):format(name),
                    ("class.packages[%s]:%s"):format(self._name, name),
                    "0.14.0", "0.16.0", _deprecate_class_funcs)
      return func(table.unpack(inputs, 1, select("#", ...) + 1))
    end
  end

  if not notable then
    self.exports[name] = function (...)
      local inputs = {...}
      if type(inputs[1]) ~= "table" or inputs[1].type ~= "package" then
        table.insert(inputs, 1, self)
      end
      SU.deprecated(("require('packages.%s').exports.%s"):format(self._name, name),
                    ("class.packages[%s]:%s"):format(self._name, name),
                    "0.14.0", "0.16.0", _deprecate_exports_table)
      return func(table.unpack(inputs, 1, select("#", ...) + 1))
    end
  end

end

return package

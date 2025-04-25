--- SILE package class.
-- @interfaces packages

local module = require("types.module")

local package = pl.class(module)
package.type = "package"

package.class = nil

-- For shimming packages that used to have legacy exports
package.exports = {}

function package:_init (_options)
   self.class = SILE.scratch.half_initialized_class or SILE.documentState.documentClass
   module._init(self)
   if not self.class then
      SU.error("Attempted to initialize package before class, should have been queued in the preamble", true)
   end
end

function package:loadPackage (packname, options, reload)
   return self.class:loadPackage(packname, options, reload)
end

function package:reloadPackage (packname, options)
   return self.class:reloadPackage(packname, options)
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

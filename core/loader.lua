local function core_loader (scope)
   return setmetatable({}, {
      __index = function (self, key)
         local spec = ("%s.%s"):format(scope, key)
         local status, module = pcall(require, spec)
         if not status then
            if scope == "languages" then
               SU.warn(
                  ("Unable to load support for language '%s' (not found or unparsable), handling with generic unicode module."):format(
                     key
                  )
               )
               local unicode = require("languages.unicode")
               local language = pl.class(unicode)
               language._name = key
               self[key] = language
               return language
            else
               SU.error(("Unable to load core module %s:\n%s"):format(spec, module))
            end
         end
         self[key] = module
         return module
      end,
   })
end

return core_loader

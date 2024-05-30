local fontManager = {}
fontManager.fontconfig = require("justenoughfontconfig")
pcall(function ()
   fontManager.macfonts = require("macfonts")
end)

fontManager.face = function (self, ...)
   local manager
   if SILE.forceFontManager then
      manager = self[SILE.forceFontManager]
   else
      manager = self.macfonts and self.macfonts or self.fontconfig
   end
   if not manager then
      SU.error("Failed to load any working font manager")
   end
   return manager._face(...)
end

return fontManager

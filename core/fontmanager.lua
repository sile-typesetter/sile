local fontManager = {}
fontManager.fontconfig = require("justenoughfontconfig")
pcall(function () fontManager.macfonts = require("macfonts") end)

fontManager.face = function (self, ...)
  local manager = self.macfonts and self.macfonts or self.fontconfig
  return manager._face(...)
end

return fontManager

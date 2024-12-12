local fontManager = {}

fontManager.fontconfig = require("justenoughfontconfig")

local has_macfonts, macfonts = pcall(require, "macfonts")
if has_macfonts and macfonts then
   fontManager.macfonts = macfonts
end

local function create_macfonts_fallback (self)
   return function (...)
      SU.debug("fonts", "Checking via macfonts")
      local status, result = pcall(self.macfonts._face, ...)
      if status and result and result.filename then
         SU.debug("fonts", "Found, returning result")
         return result
      else
         SU.debug("fonts", "Not found, trying fontconfig instead")
         return self.fontconfig._face(...)
      end
   end
end

fontManager.face = function (self, ...)
   local face
   if SILE.input.fontmanager then
      face = self[SILE.input.fontmanager]._face
   elseif has_macfonts then
      face = create_macfonts_fallback(self)
   else
      face = self.fontconfig._face
   end
   return face(...)
end

return fontManager

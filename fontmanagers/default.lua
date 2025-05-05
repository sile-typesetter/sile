local base = require("fontmanagers.base")

local fontconfig = require("fontmanagers.fontconfig")
local macfonts = require("fontmanagers.macfonts")

local fontmanager = pl.class(base)
fontmanager._name = "default"

function fontmanager:_init ()
   base._init(self)
   local havefontconfig, fc = pcall(fontconfig)
   if havefontconfig then
      self.fontconfig = fc
   end
   local havemacfonts, mf = pcall(macfonts)
   if havemacfonts then
      self.macfonts = mf
   end
end

function fontmanager:face (options)
   if self.macfonts then
      SU.debug("fontmanager", "Checking via macfonts")
      local status, result = pcall(self.macfonts.face, self.macfonts, options)
      if status and result and result.filename then
         SU.debug("fontmanager", "Found via macfonts, returning result")
         return result
      end
   end
   if self.fontconfig then
      SU.debug("fontmanager", "Checking via fontconfig")
      local status, result = pcall(self.fontconfig.face, self.fontconfig, options)
      if status and result and result.filename then
         SU.debug("fontmanager", "Found via fontconfig, returning result")
         return result
      end
   end
   SU.debug("fontmanager", "Unable to find font via any manager")
end

return fontmanager

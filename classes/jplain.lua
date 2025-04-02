--- jplain document class.
-- @use classes.jplain

-- Basic! Transitional! In development! Not very good! Don't use it!
local tplain = require("classes.tplain")

local class = pl.class(tplain)
class._name = "jplain"

function class:_init (options)
   tplain._init(self, options)
   SILE.settings:set("font.family", "Noto Sans CJK JP", true)
   self:registerPostinit(function (_)
      SILE.settings:set("document.language", "ja", true)
   end)
end

return class

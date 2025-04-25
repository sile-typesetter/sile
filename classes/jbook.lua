--- jbook document class.
-- @use classes.jbook

local tbook = require("classes.tbook")

local class = pl.class(tbook)
class._name = "jbook"

function class:_init (options)
   tbook._init(self, options)
   self.settings:set("font.family", "Noto Sans CJK JP", true)
   self:registerPostinit(function (_)
      self.settings:set("document.language", "ja", true)
   end)
end

class.declareOptions = tbook.declareOptions

class.setOptions = tbook.setOptions

return class

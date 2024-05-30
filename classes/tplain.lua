-- Basic! Transitional! In development! Not very good! Don't use it!
local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "tplain"

class.defaultFrameset.content = {
   left = "8.3%pw",
   top = "11.6%ph",
   gridsize = 10,
   linegap = 7,
   linelength = 50,
   linecount = 30,
}

-- The classes tplain and tbook inherit from plain and book respectively but also
-- have this bit in common; this makes it accessible
function class:_t_common ()
   self:loadPackage("font-fallback")
   self:loadPackage("hanmenkyoshi")
   self:registerPostinit(function (class_)
      class_:bidiDisableTypesetter(SILE.typesetter)
      class_:bidiDisableTypesetter(SILE.typesetters.base)
   end)
   self.defaultFrameset.content.tate = self.options.layout == "tate"
   self:declareHanmenFrame("content", self.defaultFrameset.content)
   SILE.settings:set("document.parindent", SILE.nodefactory.glue("10pt"))
end

function class:_init (options)
   plain._init(self, options)
   class._t_common(self)
end

function class:declareOptions ()
   plain.declareOptions(self)
   self:declareOption("layout", function (_, value)
      if value then
         self.layout = value
         if value == "tate" then
            self:loadPackage("tate")
         end
      end
      return self.layout
   end)
end

function class:setOptions (options)
   options.layout = options.layout or "yoko"
   plain.setOptions(self, options)
end

return class

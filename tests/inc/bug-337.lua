local base = require("packages.base")

local package = pl.class(base)
package._name = "bug-337"

function package:_init (options)
   base._init(self, options)

   self.class:defineMaster({
      id = "right",
      firstContentFrame = "content",
      frames = {
         content = {
            left = "0",
            right = "100%pw",
            top = "0",
            bottom = "top(folio)",
         },
         folio = {
            left = "left(content)",
            right = "right(content)",
            height = "10pt",
            bottom = "100%ph",
         },
      },
   })
   self.class:defineMaster({
      id = "left",
      firstContentFrame = "content",
      frames = {},
   })
   self.class:mirrorMaster("right", "left")
   self.class:switchMasterOnePage("right")

   self.class:loadPackage("cropmarks")
end

function package:registerCommands ()
   self:registerCommand("printPageInPoints", function ()
      local w = SILE.types.measurement("100%pw"):tonumber()
      local h = SILE.types.measurement("100%ph"):tonumber()
      SILE.typesetter:typeset(("%.0fpt × %.0fpt"):format(w, h))
   end)
end

return package

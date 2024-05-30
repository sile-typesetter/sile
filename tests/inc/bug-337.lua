local base = require("packages.base")

local package = pl.class(base)
package._name = "bug-337"

function package:_init (class)
   base._init(self, class)

   class:defineMaster({
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
   class:defineMaster({
      id = "left",
      firstContentFrame = "content",
      frames = {},
   })
   class:mirrorMaster("right", "left")
   class:switchMasterOnePage("right")

   class:loadPackage("cropmarks")
end

function package:registerCommands ()
   self.class:registerCommand("printPageInPoints", function ()
      local w = SILE.measurement("100%pw"):tonumber()
      local h = SILE.measurement("100%ph"):tonumber()
      SILE.typesetter:typeset(("%.0fpt × %.0fpt"):format(w, h))
   end)
end

return package

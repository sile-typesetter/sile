local plain = require("classes.plain")
local testtwocol = pl.class(plain)
testtwocol._name = "testtwocol"

local gutterWidth = "3%pw"

testtwocol.defaultFrameset = {}
testtwocol.firstContentFrame = "contentA"

function testtwocol:_init (options)
   plain._init(self, options)
   self:declareFrame("contentA", {
      left = "left(content)",
      right = "left(gutter)",
      top = "5%ph",
      bottom = "83.3%ph",
      next = "contentB",
      balanced = true,
   })
   self:declareFrame("contentB", {
      left = "right(gutter)",
      width = "width(contentA) * 2 / 3",
      right = "right(content)",
      top = "5%ph",
      bottom = "top(footnotes)",
      balanced = true,
   })
   self:declareFrame("gutter", { left = "right(contentA)", right = "left(contentB)", width = gutterWidth })
   self:declareFrame(
      "footnotes",
      { left = "left(contentB)", right = "right(contentB)", height = "0", bottom = "83.3%ph" }
   )
   self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = { contentB = 1 } })
   return self
end

return testtwocol

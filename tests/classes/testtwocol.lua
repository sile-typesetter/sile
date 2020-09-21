local plain = SILE.require("plain", "classes")
local testtwocols = plain { id = "testtwocols" }

local gutterWidth = "3%pw"

testtwocols.defaultFrameset = {}
testtwocols.firstContentFrame = "contentA"

testtwocols.init = function(self)
  self:declareFrame("contentA", {left = "left(content)", right = "left(gutter)", top = "5%ph", bottom = "83.3%ph", next = "contentB", balanced = true })
  self:declareFrame("contentB", {left = "right(gutter)", width="width(contentA) * 2 / 3", right = "right(content)", top = "5%ph", bottom = "top(footnotes)", balanced = true })
  self:declareFrame("gutter", {left = "right(contentA)", right = "left(contentB)", width = gutterWidth })
  self:declareFrame("footnotes", { left="left(contentB)", right = "right(contentB)", height = "0", bottom="83.3%ph"})
  self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = { contentB = 1 } } )
  return plain.init(self)
end

return testtwocols

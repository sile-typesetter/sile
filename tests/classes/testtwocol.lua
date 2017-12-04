local plain = SILE.require("plain", "classes")
local testtwocols = plain { id = "testtwocols" }

local gutterWidth = "3%pw"
testtwocols:declareFrame("contentA", {left = "left(content)", right = "left(gutter)", top = "5%ph", bottom = "83.3%ph", next = "contentB", balanced = true })
testtwocols:declareFrame("contentB", {left = "right(gutter)", width="width(contentA) * 2 / 3", right = "right(content)", top = "5%ph", bottom = "top(footnotes)", balanced = true })
testtwocols:declareFrame("gutter", {left = "right(contentA)", right = "left(contentB)", width = gutterWidth })
testtwocols:declareFrame("footnotes", { left="left(contentB)", right = "right(contentB)", height = "0", bottom="83.3%ph"})

testtwocols.pageTemplate.firstContentFrame = testtwocols.pageTemplate.frames["contentA"]

testtwocols.init = function(self)
  testtwocols:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = { contentB = 1 } } )
  return plain.init(self)
end

return testtwocols
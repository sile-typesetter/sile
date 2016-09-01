local plain = SILE.require("classes/plain")
local testsidenote = plain { id = "testsidenote" }

local gutterWidth = "3%pw"
testsidenote:declareFrame("contentA", {left = "left(content)", right = "left(gutter)", top = "top(content)", bottom = "bottom(content)" })
testsidenote:declareFrame("sidenotes", {left = "right(gutter)", width="width(contentA) * 2 / 3", right = "right(content)", top = "top(content)", bottom = "bottom(content)", balanced = true })
testsidenote:declareFrame("gutter", {left = "right(contentA)", right = "left(sidenotes)", width = gutterWidth })

testsidenote.pageTemplate.firstContentFrame = testsidenote.pageTemplate.frames["contentA"]

local insertions = SILE.require("packages/insertions")
SILE.require("packages/footnotes")

testsidenote.init = function(self)
  insertions.exports:initInsertionClass("footnote", {
    maxHeight = SILE.length.new({length = SILE.toPoints("75", "%ph") }),
    topBox = SILE.nodefactory.zeroVglue,
    interInsertionSkip = SILE.length.parse("1ex"),
    insertInto = { frame = "sidenotes", ratio = 0 },
    stealFrom = {  },
  })
  return plain.init(self)
end

return testsidenote
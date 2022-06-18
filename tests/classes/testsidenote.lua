local plain = require("classes.plain")
local testsidenote = pl.class(plain)
testsidenote._name = "testsidenote"

local gutterWidth = "3%pw"

function testsidenote:_init (options)
  plain._init(self, options)
  self:declareFrame("contentA", {left = "left(content)", right = "left(gutter)", top = "top(content)", bottom = "bottom(content)" })
  self:declareFrame("sidenotes", {left = "right(gutter)", width="width(contentA) * 2 / 3", right = "right(content)", top = "top(content)", bottom = "bottom(content)", balanced = true })
  self:declareFrame("gutter", {left = "right(contentA)", right = "left(sidenotes)", width = gutterWidth })
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames["contentA"]
  self:loadPackage("insertions")
  self:loadPackage("footnotes")
  self:initInsertionClass("footnote", {
    maxHeight = SILE.length("75%ph"):absolute(),
    topBox = SILE.nodefactory.zerovglue(),
    interInsertionSkip = SILE.length("1ex"),
    insertInto = { frame = "sidenotes", ratio = 0 },
    stealFrom = {  },
  })
  return self
end

return testsidenote

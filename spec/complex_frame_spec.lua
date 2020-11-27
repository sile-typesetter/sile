SILE = require("core/sile")
SILE.backend = "dummy"
SILE.init()

local tClass = SILE.classes.base({})

tClass:declareFrame("a", { left = "1pt", right = "12pt", top = "1pt", bottom = "top(b)" })
tClass:declareFrame("b", { left = "1pt", right = "12pt", bottom = "12pt", height="4pt" })

SILE.documentState.thisPageTemplate = tClass.pageTemplate

describe("Overlapping frame definitions", function()
  it("should work", function() assert.is.truthy(tClass) end)

  describe("Frame B", function()
    local b = SILE.getFrame("b")
    local h = b:height():tonumber()
    local t1 = b:top():tonumber()
    it("should have height", function () assert.is.equal(4, h) end)
    it("should have top", function () assert.is.equal(8, t1) end)
  end)

  describe("Frame A", function()
    local a = SILE.getFrame("a")
    local aBot = a:bottom():tonumber()
    local aHt1 = a:height():tonumber()
    it("should have bottom", function () assert.is.equal(8, aBot) end)
    it("should have height", function () assert.is.equal(7, aHt1) end)
  end)
end)

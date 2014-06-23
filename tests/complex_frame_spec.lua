SILE = require("core/sile")
assert = require "luassert"
tClass = SILE.baseClass {}

tClass:declareFrame("a", { left = "1pt", right = "12pt", top = "1pt", bottom = "top(b)" })
tClass:declareFrame("b", { left = "1pt", right = "12pt", bottom = "12pt", height="4pt" })

SILE.documentState.thisPageTemplate  = tClass.pageTemplate

describe("Overlapping frame definitions", function()
  it("should work", function()
    assert.is.truthy(tClass)
  end)
  describe("Frame B", function()
    b = SILE.getFrame("b")
    local h = b:height()
    t1 = b:top()
    it("should have height", function () assert.is.equal(h,4) end)
    it("should have top", function () assert.is.equal(t1,8) end)
 end)
 describe("Frame A", function()
    a = SILE.getFrame("a")
    aBot = a:bottom()
    aHt1 = a:height()
    it("should have bottom", function () assert.is.equal(aBot,8) end)
    it("should have height", function () assert.is.equal(aHt1,7) end)
 end)
 describe("Increase b", function()
    b._height = 1
    h2 = b:height()
    it("should have height", function () assert.is.equal(b:height(),1) end)
    a = SILE.getFrame("a")
    aBot2 = a:bottom()
    it("should shrink", function () assert.is.equal(aBot2,11) end)

  end)

end)

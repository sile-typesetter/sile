SILE = require("core.sile")

SILE.backend = "dummy"
SILE.init()

local base = require("classes.base")
local tClass = pl.class(base)
tClass._name = "tClass"

tClass.defaultFrameset = {
  a = {
    left = "1pt",
    right = "12pt",
    top = "1pt",
    bottom = "top(b)"
  },
  b = {
    left = "1pt",
    right = "12pt",
    bottom = "12pt",
    height="4pt"
  }
}

tClass.firstContentFrame = "a"

function tClass:_init ()
  base._init(self)
  return self
end

SILE.documentState.documentClass = tClass()
SILE.documentState.documentClass:start()

describe("Overlapping frame definitions", function()
  it("should work", function()
    assert.is.truthy(SILE.documentState.documentClass._initialized)
  end)

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

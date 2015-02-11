SILE = require("core/sile")
assert = require "luassert"
describe("The frame factory", function()
  it("should exist", function()
    assert.is.truthy(SILE.newFrame)
  end)
  describe("Simple", function()
    local frame = SILE.newFrame({ id = "hello", top = 20, left = 30, bottom = 200, right = 300 })
    it("should exist", function() assert.is.truthy(frame) end)
    it("should have width", function () assert.is.equal(frame:width(),270) end)
    it("should have height", function () assert.is.equal(frame:height(),180) end)
  end)

end)

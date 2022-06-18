SILE = require("core.sile")

describe("SILE.utilities", function()
  it("should exist", function()
    assert.is.truthy(SU)
  end)

  describe("utf8_to_utf16be_hexencoded ", function()
    it("should hex encode input", function()
      local str = "foo"
      local out = "feff0066006f006f"
      assert.is.equal(out, SU.utf8_to_utf16be_hexencoded(str))
    end)
  end)

end)

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

  describe("formatNumber", function ()

    SILE.documentState = { documentClass = { state = { } } }
    SILE.typesetter = SILE.defaultTypesetter(SILE.newFrame({ id = "dummy" }))

    describe ("Esperanto", function ()
      SILE.languageSupport.loadLanguage("eo")

      it("should format strings", function ()
        assert.is.equal("miliono", SU.formatNumber.eo.string(1000000))
        assert.is.equal("miliono kaj unu", SU.formatNumber.eo.string(1000001))
        assert.is.equal("tri milionoj kaj tri", SU.formatNumber.eo.string(3000003))
        assert.is.equal("tri miliardoj kaj tri cent tri dek tri milionoj kaj tri cent mil tri dek", SU.formatNumber.eo.string(3333300030))
      end)

      it("should format nths", function ()
        assert.is.equal("1a", SU.formatNumber.eo.nth(1))
        assert.is.equal("99a", SU.formatNumber.eo.nth(99))
      end)

    end)

  end)

end)

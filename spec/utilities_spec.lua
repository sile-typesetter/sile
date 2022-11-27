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
      SILE.call("language", { main = "eo" }) -- Really load AND activate the language
      -- The test assumes Espeeranto has its own language-specific hooks, bypassing ICU.

      it("should format strings", function ()
        -- Directly checking the language-specific hooks
        assert.is.equal("miliono", SU.formatNumber.eo.string(1000000))
        assert.is.equal("miliono kaj unu", SU.formatNumber.eo.string(1000001))
        assert.is.equal("tri milionoj kaj tri", SU.formatNumber.eo.string(3000003))
        assert.is.equal("tri miliardoj kaj tri cent tri dek tri milionoj kaj tri cent mil tri dek", SU.formatNumber.eo.string(3333300030))
        -- Called via basic SILE.formatNumber() when the language is set.
        assert.is.equal("miliono kaj unu", SU.formatNumber(1000001, { style = "string" }))
      end)

      it("should format ordinal numbers", function ()
        -- Directly checking the language-specific hooks
        assert.is.equal("1a", SU.formatNumber.eo.ordinal(1))
        assert.is.equal("99a", SU.formatNumber.eo.ordinal(99))
        -- Called via basic SILE.formatNumber() when the language is set.
        assert.is.equal("1a", SU.formatNumber(1, { style = "ordinal" }))
        assert.is.equal("99a", SU.formatNumber(99, { style = "ordinal" }))
      end)
    end)

    describe ("French", function ()
      SILE.call("language", { main = "fr" }) -- Really load AND activate the language
      -- The test assumes French is relying on ICU.

      it("should format strings", function ()
        assert.is.equal("mille neuf cent quatre-vingt-quatre", SU.formatNumber(1984, { style = "string" }))
      end)

      it("should format default numbers", function ()
        assert.is.equal("1984", SU.formatNumber(1984, { style = "default" }))
      end)

      it("should format decimal numbers", function ()
        assert.is.equal("1 984", -- N.B. Contains a non-breaking space
                        SU.formatNumber(1984, { style = "decimal" }))
      end)

      it("should format ordinal numbers", function ()
        assert.is.equal("1 984e", -- N.B. Contains a non-breaking space
                        SU.formatNumber(1984, { style = "ordinal" }))
      end)
    end)

    describe ("English", function ()
      SILE.call("language", { main = "en" }) -- Really load AND activate the language
      -- The test assumes English is relying both on ICU and language-specific hooks

      it("should format strings", function ()
        assert.is.equal("one thousand nine hundred eighty-four", SU.formatNumber(1984, { style = "string" }))
      end)

      it("should format default numbers", function ()
        assert.is.equal("1984", SU.formatNumber(1984, { style = "default" }))
      end)

      it("should format decimal numbers", function ()
        assert.is.equal("1,984", SU.formatNumber(1984, { style = "decimal" }))
      end)

      it("should format ordinal numbers", function ()
        assert.is.equal("1984’th", SU.formatNumber(1984, { style = "ordinal" }))
      end)
    end)

    describe ("Russian", function ()
      SILE.call("language", { main = "ru" }) -- Really load AND activate the language
      -- The test assumes Arabic language is relying on ICU

      it("should format strings", function ()
        assert.is.equal("одна тысяча девятьсот восемьдесят четыре", SU.formatNumber(1984, { style = "string" }))
      end)

      it("should format default numbers", function ()
        assert.is.equal("1984", SU.formatNumber(1984, { style = "default" }))
      end)

      it("should format decimal numbers", function ()
        assert.is.equal("1 984", -- N.B. Contains a non-breaking space
                        SU.formatNumber(1984, { style = "decimal" }))
      end)

      it("should format ordinal numbers", function ()
        assert.is.equal("1 984.", -- N.B. Contains a non-breaking space
                        SU.formatNumber(1984, { style = "ordinal" }))
      end)
    end)

    describe ("Arabic", function ()
      SILE.call("language", { main = "ar" }) -- Really load AND activate the language
      -- The test assumes Arabic language is relying on ICU

      it("should format default numbers", function ()
        assert.is.equal("١٩٨٤", SU.formatNumber(1984, { style = "default" }))
      end)

      it("should format decimal numbers", function ()
        assert.is.equal("١٬٩٨٤", SU.formatNumber(1984, { style = "decimal" }))
      end)

      it("should format ordinal numbers", function ()
        assert.is.equal("١٬٩٨٤.", SU.formatNumber(1984, { style = "ordinal" }))
      end)
    end)

    describe ("Numbering systems", function ()
      SILE.call("language", { main = "en" }) -- Really load AND activate the language
      -- Just to have a language

      it("should format 'latin' numbers", function ()
        assert.is.equal("2", SU.formatNumber(2, { system = "latn" }))
        assert.is.equal("2", SU.formatNumber(2, { system = "arabic" }))
      end)

      it("should format roman number", function ()
        assert.is.equal("mcmlxxxiv", SU.formatNumber(1984, { system = "roman" }))
      end)

      it("should format ROMAN number", function ()
        assert.is.equal("MCMLXXXIV", SU.formatNumber(1984, { system = "ROMAN" }))
      end)

      it("should format alpha number", function ()
        assert.is.equal("b", SU.formatNumber(2, { system = "alpha" }))
      end)

      it("should format ALPHA number", function ()
        assert.is.equal("B", SU.formatNumber(2, { system = "Alpha" }))
      end)

      it("should format 'arab' numbers", function ()
        assert.is.equal("٢", SU.formatNumber(2, { system = "arab" }))
      end)
    end)
  end)

end)

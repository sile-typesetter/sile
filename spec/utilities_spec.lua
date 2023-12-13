SILE = require("core.sile")

describe("SILE.utilities", function()
  it("should exist", function()
    assert.is.truthy(SU)
  end)

  describe("deprecated", function ()
    it("should compute errors based on semver", function()
      SILE.version = "v0.1.10.r4-h5d5dd3b"
      SU.warn = function () end
      assert.has.errors(function() SU.deprecated("foo", "bar", "0.1.9", "0.1.9") end)
      assert.has_no.errors(function() SU.deprecated("foo", "bar", "0.1.11", "0.1.11") end)
    end)
  end)

  describe("utf8_to_utf16be_hexencoded ", function()
    it("should hex encode input", function()
      local str = "foo"
      local out = "feff0066006f006f"
      assert.is.equal(out, SU.utf8_to_utf16be_hexencoded(str))
    end)
  end)

  describe("formatNumber", function ()

    local icu = require("justenoughicu")
    local icu73plus = tostring(icu.version()) >= "73.0"

    SILE.documentState = { documentClass = { state = { } } }
    SILE.typesetter = SILE.typesetters.base(SILE.newFrame({ id = "dummy" }))

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
        assert.is.equal("1,984th", SU.formatNumber(1984, { style = "ordinal" }))
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
        local expectation = icu73plus and "1 984" or "1 984."
        assert.is.equal(expectation, -- N.B. Contains a non-breaking space
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
        local expectation = icu73plus and "١٬٩٨٤" or "١٬٩٨٤."
        assert.is.equal(expectation, SU.formatNumber(1984, { style = "ordinal" }))
      end)
    end)

    describe ("Numbering systems", function ()
      SILE.call("language", { main = "en" }) -- Really load AND activate the language
      -- Just to have a language

      it("should format 'latin' numbers", function ()
        assert.is.equal("2", SU.formatNumber(2, { system = "latn" }))
        assert.is.equal("2", SU.formatNumber(2, { system = "arabic" }))
      end)

      it("should format roman numbers", function ()
        assert.is.equal("mcmlxxxiv", SU.formatNumber(1984, { system = "roman" }))
      end)

      it("should format ROMAN numbers", function ()
        assert.is.equal("MCMLXXXIV", SU.formatNumber(1984, { system = "ROMAN" }))
      end)

      it("should format alpha numbers", function ()
        assert.is.equal("b", SU.formatNumber(2, { system = "alpha" }))
      end)

      it("should format ALPHA numbers", function ()
        assert.is.equal("B", SU.formatNumber(2, { system = "Alpha" }))
      end)

      it("should format 'arab' numbers", function ()
        assert.is.equal("٢", SU.formatNumber(2, { system = "arab" }))
      end)

      it("should format greek numbers", function ()
        assert.is.equal("β", SU.formatNumber(2, { system = "greek" }))
      end)

      it("should format GREEK numbers", function ()
        assert.is.equal("Β", SU.formatNumber(2, { system = "Greek" }))
      end)

    end)
  end)

  describe("collatedSort", function ()

    SILE.documentState = { documentClass = { state = { } } }
    SILE.typesetter = SILE.typesetters.base(SILE.newFrame({ id = "dummy" }))

    describe ("French", function ()
      SILE.call("language", { main = "fr" }) -- Really load AND activate the language

      -- Our reference 'unsorted' table.
      -- Just as table.sort(t), SU.collatedSort(t) has a side-effect on the table, we'll need
      -- to shallow copy it, for each test to be independent from the others.
      local original = {
        "Albert", "Jean2", "Alain", "Jean100", "alain", "alinoé", "Jean-Paul", "Alinéa", "Jean2", "jeanne" }

      it("should have expected default sorting", function ()
        local sortme = pl.tablex.copy(original)
        SU.collatedSort(sortme) -- with default options
        assert.is.same({
          "alain", "Alain", "Albert","Alinéa", "alinoé", "Jean2", "Jean2", "Jean100", "jeanne", "Jean-Paul" }, sortme)
      end)
      it("should have expected sorting when ignorePunctuation is disabled", function ()
        local sortme = pl.tablex.copy(original)
        SU.collatedSort(sortme, { ignorePunctuation = false })
        assert.is.same({
          -- Jean-Paul is the guinea pig!
          "alain", "Alain", "Albert", "Alinéa", "alinoé", "Jean-Paul", "Jean2", "Jean2", "Jean100", "jeanne" }, sortme)
      end)
      it("should have expected sorting when numericOrdering is disabled", function ()
        local sortme = pl.tablex.copy(original)
        SU.collatedSort(sortme, { numericOrdering = false })
        assert.is.same({
          -- Jean100 and the Jean2 are the guinea pigs!
          "alain", "Alain", "Albert", "Alinéa", "alinoé", "Jean100", "Jean2", "Jean2", "jeanne", "Jean-Paul" }, sortme)
      end)
      it("should have expected sorting when caseFirst is 'upper'", function ()
        local sortme = pl.tablex.copy(original)
        SU.collatedSort(sortme, { caseFirst = "upper" })
        assert.is.same({
          -- Alain is the guinea pig!
          "Alain", "alain", "Albert", "Alinéa", "alinoé", "Jean2", "Jean2", "Jean100", "jeanne", "Jean-Paul" }, sortme)
      end)
      it("should have expected sorting when language-specific options are configured", function ()
        -- WARNING: This is expected to be used for languages where the default options
        -- are not appropriate. I'm told for example that Japanese may need strength=4.
        -- I've not idea however, so let's BREAK the default French rules for testing!
        SU.collatedSort.fr = { caseFirst = "upper", numericOrdering = false }
        local sortme = pl.tablex.copy(original)
        SU.collatedSort(sortme) -- with default options as overriden.
        assert.is.same({
          -- Alain and the Jean guys are the guinea pigs!
          "Alain", "alain", "Albert", "Alinéa", "alinoé", "Jean100", "Jean2", "Jean2", "jeanne", "Jean-Paul" }, sortme)
      end)
    end)
  end)

end)

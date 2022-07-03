SILE = require("core.sile")

describe("Language module", function ()

  describe("Norwegian", function ()

    local hyphenate = SILE.showHyphenationPoints

    SILE.languageSupport.loadLanguage("no")
    SILE.fluent:set_locale("no")

    it("should hyphenate", function ()
      assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "no"))
      assert.is.equal("atten-de", hyphenate("attende", "no"))
    end)

    it("should have localizations", function ()
      SILE.fluent:set_locale("no")
      local hello = SILE.fluent:get_message("hello")({ name = "Busted" })
      assert.is.equal("Hei Busted!", hello)
    end)

    describe("Norwegian Bokmål", function ()

      SILE.languageSupport.loadLanguage("nb")
      SILE.fluent:set_locale("nb")

      it("should hyphenate", function ()
        assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "nb"))
        assert.is.equal("atten-de", hyphenate("attende", "nb"))
      end)

      it("should have localizations", function ()
        local hello = SILE.fluent:get_message("hello")({ name = "Busted" })
        assert.is.equal("Hei Busted!", hello)
      end)

    end)

    describe("Norwegian Nynorsk", function ()

      SILE.languageSupport.loadLanguage("nn")
      SILE.fluent:set_locale("nn")

      it("should hyphenate", function ()
        assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "nn"))
        assert.is.equal("att-en-de", hyphenate("attende", "nn"))
      end)

      it("should have localizations", function ()
        local hello = SILE.fluent:get_message("hello")({ name = "Busted" })
        assert.is.equal("Hei Busted!", hello)
      end)

    end)

  end)

end)

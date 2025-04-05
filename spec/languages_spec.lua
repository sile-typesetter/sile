SILE = require("core.sile")
SILE.input.backend = "debug"
SILE.init()

-- Work around not having an active class in this test but needing language modules
SILE.typesetter = SILE.typesetters.default()

describe("Language module", function ()
   it("should set env locale", function ()
      SILE.call("language", { main = "tr" })
      local syslang = os.getenv("LANG")
      assert.is.equal("tr", syslang)
   end)

   describe("Norwegian", function ()
      SILE.call("language", { main = "no" })

      local hyphenator = SILE.typesetter.language.hyphenator

      it("should hyphenate", function ()
         assert.is.equal("Nor-we-gian", hyphenator:showHyphenationPoints("Norwegian", "no"))
         assert.is.equal("atten-de", hyphenator:showHyphenationPoints("attende", "no"))
      end)

      it("should have localizations", function ()
         local hello = fluent:get_message("hello")({ name = "Busted" })
         assert.is.equal("Hei <em>Busted</em>!", hello)
      end)

      describe("Norwegian Bokmål", function ()
         SILE.call("language", { main = "nb" })

         it("should hyphenate", function ()
            assert.is.equal("Nor-we-gian", hyphenator:showHyphenationPoints("Norwegian", "nb"))
            assert.is.equal("atten-de", hyphenator:showHyphenationPoints("attende", "nb"))
         end)

         it("should have localizations", function ()
            local hello = fluent:get_message("hello")({ name = "Busted" })
            assert.is.equal("Hei <em>Busted</em>!", hello)
         end)
      end)

      describe("Norwegian Nynorsk", function ()
         SILE.call("language", { main = "nn" })

         it("should hyphenate", function ()
            assert.is.equal("Nor-we-gian", hyphenator:showHyphenationPoints("Norwegian", "nn"))
            assert.is.equal("att-en-de", hyphenator:showHyphenationPoints("attende", "nn"))
         end)

         it("should have localizations", function ()
            local hello = fluent:get_message("hello")({ name = "Busted" })
            assert.is.equal("Hei <em>Busted</em>!", hello)
         end)
      end)
   end)
end)

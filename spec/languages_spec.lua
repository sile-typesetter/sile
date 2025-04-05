SILE = require("core.sile")

describe("Language module", function ()
   it("should set env locale", function ()
      SILE.call("language", { main = "tr" })
      local syslang = os.getenv("LANG")
      assert.is.equal("tr", syslang)
   end)

   local hyphenate = SILE.showHyphenationPoints

   describe("Norwegian", function ()
      SILE.call("language", { main = "no" })

      it("should hyphenate", function ()
         assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "no"))
         assert.is.equal("atten-de", hyphenate("attende", "no"))
      end)

      it("should have localizations", function ()
         local hello = fluent:get_message("hello")({ name = "Busted" })
         assert.is.equal("Hei <em>Busted</em>!", hello)
      end)

      describe("Norwegian Bokmål", function ()
         SILE.call("language", { main = "nb" })

         it("should hyphenate", function ()
            assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "nb"))
            assert.is.equal("atten-de", hyphenate("attende", "nb"))
         end)

         it("should have localizations", function ()
            local hello = fluent:get_message("hello")({ name = "Busted" })
            assert.is.equal("Hei <em>Busted</em>!", hello)
         end)
      end)

      describe("Norwegian Nynorsk", function ()
         SILE.call("language", { main = "nn" })

         it("should hyphenate", function ()
            assert.is.equal("Nor-we-gian", hyphenate("Norwegian", "nn"))
            assert.is.equal("att-en-de", hyphenate("attende", "nn"))
         end)

         it("should have localizations", function ()
            local hello = fluent:get_message("hello")({ name = "Busted" })
            assert.is.equal("Hei <em>Busted</em>!", hello)
         end)
      end)

   end)

   describe("Uyghur", function ()
      SILE.call("language", { main = "ug" })

      it("should hyphenate", function ()
         assert.is.equal("?????????", hyphenate("كۈتۈپخانا", "ug"))
      end)

      it("should fallback to Turkish for Latin input", function ()
         assert.is.equal("ky-typ-ka-na", hyphenate("kytypkana", "ug"))
      end)

   end)
end)

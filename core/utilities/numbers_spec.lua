SILE = require("core.sile")
SILE.init()
SILE.utilities.error = error
SILE.utilities.warn = function () end

describe("SILE.utilities", function ()

   describe("formatNumber", function ()
      local icu = require("justenoughicu")
      local icu73plus = tostring(icu.version()) >= "73.0"

      describe("Arabic", function ()
         SILE.call("language", { main = "ar" })
         -- The test assumes Arabic language is relying on ICU

         it("should format default numbers", function ()
            assert.is.equal("١٩٨٤", SU.formatNumber(1984, { style = "default", system = "arab" }))
            assert.is.equal("۱۹۸۴", SU.formatNumber(1984, { style = "default", system = "arabext" }))
         end)

         it("should format decimal numbers", function ()
            assert.is.equal("١٬٩٨٤", SU.formatNumber(1984, { style = "decimal", system = "arab" }))
            assert.is.equal("۱٬۹۸۴", SU.formatNumber(1984, { style = "decimal", system = "arabext" }))
         end)

         it("should format ordinal numbers", function ()
            local expectation1 = icu73plus and "١٬٩٨٤" or "١٬٩٨٤."
            local expectation2 = icu73plus and "۱٬۹۸۴" or "۱٬۹۸۴."
            assert.is.equal(expectation1, SU.formatNumber(1984, { style = "ordinal", system = "arab" }))
            assert.is.equal(expectation2, SU.formatNumber(1984, { style = "ordinal", system = "arabext" }))
         end)
      end)

      describe("Esperanto", function ()
         SILE.call("language", { main = "eo" })
         -- The test assumes Espeeranto has its own language-specific hooks, bypassing ICU.

         it("should format strings", function ()
            -- Directly checking the language-specific hooks
            assert.is.equal("miliono", SU.formatNumber.eo.string(1000000))
            assert.is.equal("miliono kaj unu", SU.formatNumber.eo.string(1000001))
            assert.is.equal("tri milionoj kaj tri", SU.formatNumber.eo.string(3000003))
            assert.is.equal(
               "tri miliardoj kaj tri cent tri dek tri milionoj kaj tri cent mil tri dek",
               SU.formatNumber.eo.string(3333300030)
            )
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

      describe("English", function ()
         SILE.call("language", { main = "en" })
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

      describe("French", function ()
         SILE.call("language", { main = "fr" })
         -- The test assumes French is relying on ICU.

         it("should format strings", function ()
            assert.is.equal("mille neuf cent quatre-vingt-quatre", SU.formatNumber(1984, { style = "string" }))
         end)

         it("should format default numbers", function ()
            assert.is.equal("1984", SU.formatNumber(1984, { style = "default" }))
         end)

         it("should format decimal numbers", function ()
            assert.is.equal(
               "1 984", -- N.B. Contains a non-breaking space
               SU.formatNumber(1984, { style = "decimal" })
            )
         end)

         it("should format ordinal numbers", function ()
            assert.is.equal(
               "1 984e", -- N.B. Contains a non-breaking space
               SU.formatNumber(1984, { style = "ordinal" })
            )
         end)
      end)

      describe("Russian", function ()
         SILE.call("language", { main = "ru" })
         -- The test assumes Arabic language is relying on ICU

         it("should format strings", function ()
            assert.is.equal(
               "одна тысяча девятьсот восемьдесят четыре",
               SU.formatNumber(1984, { style = "string" })
            )
         end)

         it("should format default numbers", function ()
            assert.is.equal("1984", SU.formatNumber(1984, { style = "default" }))
         end)

         it("should format decimal numbers", function ()
            assert.is.equal(
               "1 984", -- N.B. Contains a non-breaking space
               SU.formatNumber(1984, { style = "decimal" })
            )
         end)

         it("should format ordinal numbers", function ()
            local expectation = icu73plus and "1 984" or "1 984."
            assert.is.equal(
               expectation, -- N.B. Contains a non-breaking space
               SU.formatNumber(1984, { style = "ordinal" })
            )
         end)
      end)

      describe("Numbering systems", function ()
         SILE.call("language", { main = "en" })
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

         describe("Greek number formatting", function ()
            local function greek (n)
               return SILE.utilities.formatNumber(n, { system = "greek" })
            end

            local function Greek (n)
               return SILE.utilities.formatNumber(n, { system = "Greek" })
            end

            it("should format numbers as letters", function ()
               -- Test first letter (alpha)
               assert.is.equal("α", greek(1))

               -- Test middle of first range (mu)
               assert.is.equal("ν", greek(13))

               -- Test last letter before sigma shift (rho)
               assert.is.equal("ρ", greek(17))

               -- Test after sigma shift (tau)
               assert.is.equal("τ", greek(19))

               -- Test last letter (omega)
               assert.is.equal("ω", greek(24))
            end)

            it("should support uppercase letters", function ()
               -- Test first letter (Alpha)
               assert.is.equal("Α", Greek(1))

               -- Test middle letter (Xi)
               assert.is.equal("Ξ", Greek(14))

               -- Test last letter (Omega)
               assert.is.equal("Ω", Greek(24))
            end)

            it("should error on numbers above 24", function ()
               assert.has.errors(function ()
                  greek(25)
               end)
            end)
         end)
      end)
   end)
end)

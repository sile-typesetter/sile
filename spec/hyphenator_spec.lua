SILE = require("core.sile")
-- Using French below requires the shaper to be initialized
SILE.input.backend = "debug"
SILE.init()

describe("Hyphenation module", function ()
   SILE.call("language", { main = "fr" })
   local hyphenator = SILE.typesetter.language.hyphenator

   describe("minWord with UTF8 in input text", function ()
      -- Trigger the initialization of the hyphenator
      -- so SILE._hyphenators["fr"] is created
      hyphenator:showHyphenationPoints("série", "fr")

      -- Current lefthyphenmin and righthyphenmin values
      -- for this test (whether changed or not for the language)
      hyphenator.leftmin = 2
      hyphenator.rightmin = 2

      it("should hyphenate words longer than minWord", function ()
         hyphenator.minWord = 5 -- (Default)
         assert.is.equal("sé-rie", hyphenator:showHyphenationPoints("série", "fr"))
         -- typos: ignore start
         assert.is.equal("Lé-gè-re-ment", hyphenator:showHyphenationPoints("Légèrement", "fr"))
         -- typos: ignore end
      end)

      it("should not hyphenate words shorter than minWord", function ()
         hyphenator.minWord = 6
         -- 5 characters but 6 bytes
         assert.is.equal("série", hyphenator:showHyphenationPoints("série", "fr"))
         hyphenator.minWord = 5 -- back to default
      end)
   end)

   describe("exceptions with UTF8 in input text", function ()
      SILE.call("hyphenator:add-exceptions", {}, { "légè-rement" })

      it("should hyphenate with exception rule", function ()
         assert.is.equal("légè-rement", hyphenator:showHyphenationPoints("légèrement", "fr"))
         assert.is.equal("Légè-rement", hyphenator:showHyphenationPoints("Légèrement", "fr"))
      end)
   end)
end)

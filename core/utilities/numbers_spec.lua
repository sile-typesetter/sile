SILE = require("core.sile")
SILE.utilities.error = error

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

SILE = require("core.sile")

local rusile = require("rusile")

local callable = require("luassert.util").callable

describe("rusile", function ()
   it("should exist", function ()
      assert.is.truthy(rusile)
   end)

   describe("semver", function ()
      local semver = rusile.semver

      it("constructor should exist", function ()
         assert.is.truthy(callable(semver))
      end)

      describe("instance", function ()
         local a = semver("1.3.5")
         local b = semver("1.3.5")
         local c = semver("2.4.6")

         it("should evaluate comparisons", function ()
            assert.is.equal(a, b)
            assert.is.truthy(a == b)
            assert.is_not.equal(a, c)
            assert.is_not.truthy(a == c)
            assert.is.truthy(a < c)
            assert.is.truthy(c > b)
            assert.is.truthy(a <= b)
            assert.is.truthy(c >= b)
         end)
      end)
   end)
end)

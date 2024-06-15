SILE = require("core.sile")

describe("rusile", function ()

   it("should exist", function ()
      assert.is.truthy(SILE._rusile)
   end)

   describe("foo ", function ()
      it("should return a test string", function ()
         local str = "Hello from rusile"
         assert.is.equal(str, SILE._rusile.foo())
      end)
   end)

end)

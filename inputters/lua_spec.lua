SILE = require("core.sile")
SILE.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#LUA #inputter", function ()
   local inputter = SILE.inputters.lua()

   describe("should parse", function ()
      it("bare code", function ()
         local t = inputter:parse([[SILE.scratch.foo = 42]])
         assert.is.truthy(type(t) == "function")
         assert.is.truthy(type(SILE.scratch.foo) == "nil")
         assert.is.truthy(type(t() == "nil"))
         assert.is.equal(42, SILE.scratch.foo)
      end)

      it("functions", function ()
         local t = inputter:parse([[return function() return 6 end]])
         local b = t()
         assert.is.truthy(type(b) == "function")
         assert.is.equal(6, b())
      end)

      it("documents", function ()
         local t = inputter:parse([[return { "bar", command = "foo" }]])
         local b = t()
         assert.is.equal("foo", b.command)
         assert.is.equal("bar", b[1])
      end)
   end)

   describe("should reject", function ()
      it("invalid Lua syntax", function ()
         -- Lua 5.1 vs. others throw slightly different errors, hence partial matches
         assert.has_error_matches(function ()
            inputter:parse([[a = "b]])
         end, [[[string "a = "b"]:1: unfinished string near]], nil, true)
         assert.has_error_matches(function ()
            inputter:parse([[if]])
         end, [[[string "if"]:1: unexpected symbol near]], nil, true)
      end)
   end)
end)

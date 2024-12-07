SILE = require("core.sile")
SILE.input.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#XML #inputter", function ()
   local inputter = SILE.inputters.xml()

   describe("should parse", function ()
      it("commands with content", function ()
         local t = inputter:parse([[<foo>bar</foo>]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("bar", t[1])
      end)

      it("commands without content", function ()
         local t = inputter:parse([[<foo><bar /> baz</foo>]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("bar", t[1].command)
         assert.is.equal(" baz", t[2])
         assert.is.equal(nil, t[1][1])
      end)

      it("commands with arg", function ()
         local t = inputter:parse([[<foo baz="qiz">bar</foo>]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz", t.options.baz)
         assert.is.equal("bar", t[1])
      end)

      it("commands with multiple args", function ()
         local t = inputter:parse([[<foo baz="qiz" qiz="baz">bar</foo>]])[1][1]
         assert.is.equal("foo", t.command)
         assert.is.equal("qiz", t.options.baz)
         assert.is.equal("baz", t.options.qiz)
         assert.is.equal("bar", t[1])
      end)

      it("commands should parse only named arguments", function ()
         local t = inputter:parse([[<foo baz="qiz">bar</foo>]])[1][1]
         assert.is.equal(0, #t.options)
      end)

      -- it("commands with quoted arg with escape", function()
      --   local t = inputter:parse([[<foo baz="qiz \"qiz\"">bar</bar>]])
      --   assert.is.equal("foo", t.command)
      --   assert.is.equal("qiz \"qiz\"", t.options.baz)
      --   assert.is.equal("bar", t[1])
      -- end)
   end)

   describe("should reject", function ()
      it("commands with bad characters", function ()
         assert.has_error(function ()
            inputter:parse([[<" />]])
         end, "not well-formed (invalid token)")
         assert.has_error(function ()
            inputter:parse([[<' />]])
         end, [[not well-formed (invalid token)]])
         assert.has_error(function ()
            inputter:parse([[<"o></"o>]])
         end, [[not well-formed (invalid token)]])
      end)

      it("commands with unclosed content", function ()
         assert.has_error(function ()
            inputter:parse([[<foo>bar]])
         end, [[no element found]])
      end)

      it("mismatched environments", function ()
         assert.has_error(function ()
            inputter:parse([[<foo><bar>baz</foo></bar>]])
         end, [[mismatched tag]])
      end)
   end)
end)

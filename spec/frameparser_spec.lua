SILE = require("core.sile")

describe("The frame parser", function ()
   it("should exist", function ()
      assert.is.truthy(SILE.frameParser)
   end)

   local n = SILE.parserBits.number
   local m = SILE._frameParserBits.measurement
   local r = SILE._frameParserBits.relation

   describe("Number", function () -- also tests all the number subrules
      it("should capture number information", function ()
         assert.is.equal(0.35, n:match("0.35"))
      end)
      it("should capture number information", function ()
         assert.is.equal(-0.85, n:match("-.85"))
      end)
      it("should capture number information", function ()
         assert.is.equal(44, n:match("44 xyz"))
      end)
   end)

   describe("function", function () -- also tests identifier
      require("classes.plain")({})
      SILE.documentState.thisPageTemplate = {
         frames = {
            a = SILE.newFrame({ id = "A", top = 20, left = 30, bottom = 200, right = 300 }),
            bb3 = SILE.newFrame({ id = "B", top = 20, left = 30, bottom = 200, right = 300 }),
         },
      }
      --it("should match valid functions", function() assert.is.equal(30,r:match("left(a)")) end)
      it("should match valid functions", function ()
         assert.is.truthy(r:match("top(bb3)"))
      end)
      it("should not match invalid functions", function ()
         assert.is.falsy(r:match("xxx(a)"))
      end)
      it("should not match invalid functions", function ()
         assert.is.falsy(r:match("left(&)"))
      end)
   end)

   describe("dimensioned string", function ()
      it("should convert SILE measurements", function ()
         assert.is.equal(14.4, m:match("0.2 in"))
      end)
   end)
end)

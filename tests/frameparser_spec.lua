testingSILE = true
assert = require "luassert"
SILE = require("core/sile")
describe("The frame parser", function()
  it("should exist", function()
    assert.is.truthy(SILE.frameParser)
  end)
  local n = SILE.frameParserBits.number
  local f = SILE.frameParserBits.func
  local d = SILE.frameParserBits.dimensioned_string

  describe("Number.number", function() -- also tests all the number subrules
    it("should capture number information", function() assert.is.equal(0.35, n.number:match("0.35")) end)
    it("should capture number information", function() assert.is.equal(-.85, n.number:match("-.85")) end)
    it("should capture number information", function() assert.is.equal(44, n.number:match("44 xyz")) end)
  end)

  describe("function", function() -- also tests identifier
    SILE.documentState = {
      thisPageTemplate = {
        frames = { a = SILE.newFrame({ top = 20, left = 30, bottom = 200, right = 300 }),
                   bb3 = SILE.newFrame({ top = 20, left = 30, bottom = 200, right = 300 })
                }
      }
    }
    it("should match valid functions", function() assert.is.equal(30,f:match("left(a)")) end)
    it("should match valid functions", function() assert.is.truthy(f:match("top(bb3)")) end)
    it("should not match invalid functions", function() assert.is.falsy(f:match("xxx(a)")) end)
    it("should not match invalid functions", function() assert.is.falsy(f:match("left(&)")) end)
  end)

  describe("dimensioned string", function()
    it("should convert via SILE.measurements", function() assert.is.equal(14.4,d:match("0.2 in")) end)
  end)

  describe("complex example", function()
    it("should sum two integers", function() assert.is.equal(2,SILE.frameParser:match("1 + 1")) end)
    it("should sum two floats bracketed", function() assert.is.equal(6.7,SILE.frameParser:match("(5.5 + 1.2)")) end)
    it("should do sums", function() assert.is.equal(14,SILE.frameParser:match("2 + 3 * 4")) end)
    it("should do sums involving brackets", function() assert.is.equal(20,SILE.frameParser:match("(2 + 3) * 4")) end)
    it("should do clever things", function() assert.is.equal(182,SILE.frameParser:match("1 in + (top(a) + bottom(a))/2")) end)
    it("should do clever things", function() assert.is.equal(182,SILE.frameParser:match("(top(a) + bottom(a))/2 + 1 in")) end)

  end)

end)

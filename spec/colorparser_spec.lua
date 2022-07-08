SILE = require("core.sile")
SU.warn = function () end

describe("The color parser", function()
  local parse = SILE.colorparser
  local rebecca = {
    b = 0.6,
    g = 0.2,
    r = 0.4
  }
  local reddish = {
    c = 0,
    k = 0.3,
    m = 0.81,
    y = 0.81
  }
  it("should return the correct RGB values for a named color", function()
    assert.is.same(parse("rebeccapurple"), rebecca)
    assert.is.same(parse("RebeccaPurple"), rebecca)
  end)
  it("should return the correct RGB values for a hexadecimal specification", function()
    assert.is.same(parse("#663399"), rebecca)
    assert.is.same(parse("#639"), rebecca)
  end)
  it("should return the correct RGB values for a series of 3 numbers or percentages", function()
    assert.is.same(parse("102 51 153"), rebecca)
    assert.is.same(parse("40% 20% 60%"), rebecca)
  end)
  it("should return the correct CMYK values for a series of 4 numbers or percentages", function()
    assert.is.same(parse("0% 81% 81% 30%"), reddish)
    assert.is.same(parse("0 206.55 206.55 76.5"), reddish)
  end)
  it("should return the correct grayscale value for single number", function()
    assert.is.same(parse("204"), { l = 0.8 })
  end)

  it("error if unable to parse", function()
    assert.has.errors(function () parse("not_a_color") end)
    assert.has.errors(function () parse(nil) end)
    assert.has.errors(function () parse("") end)
  end)
end)


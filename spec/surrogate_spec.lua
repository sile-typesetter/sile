SILE = require("core.sile")
local icu = require("justenoughicu")

describe("SILE.linebreak", function()
  local chars = { 0x10000, 0x10001, 0x10002 }
  local utf8string = ""
  for i = 1,#chars do
    utf8string = utf8string .. luautf8.char(chars[i])
  end

  it("should be the right length in UTF8", function()
    assert.is.equal(#utf8string, 12)
  end)

  it("should be the right length from ICU", function()
    local res = icu.bidi_runs(utf8string, "LTR")
    assert.is.equal(res.length, 3)
  end)
end)

SILE = require("core.sile")
SILE.backend = "debug"
SILE.init()

-- These tests depend on loading specific fonts from our test fixtures. Running
-- plain `busted` is sometimes useful (e.g. for IDEs) but will not support this
-- test because fontconfig hasn't been preloaded with the font paths it would
-- need. If that's the case, just skip even defining these tests and call it
-- good. To test a complete set of tests use `make busted`.
local fcf = os.getenv("FONTCONFIG_FILE")
if not fcf then return end

describe("The OpenType loader/parser", function()
  local ot = SILE.require("core.opentype-parser")
  local face = SILE.shaper:getFace({ family = "Libertinus Serif" })
  local font = ot.parseFont(face)

  it("should convert Microsoft-platform name strings to UTF8", function()
    local version = font.names[5]["en-US"][1]
    -- Upstream project uses "Version X.YYY;RELEASE" as version string, until X
    -- becomes three digits this should be stable at 21 characters. If 42 then
    -- the UTF16 conversion isn't working.
    assert.is.equal(21, version:len())
  end)
end)

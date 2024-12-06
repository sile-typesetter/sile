SILE = require("core.sile")
SILE.input.backend = "debug"
SILE.input.fontmanager = "fontconfig"
SILE.init()

-- These tests depend on loading specific fonts from our test fixtures. Running
-- plain `busted` is sometimes useful (e.g. for IDEs) but will not support this
-- test because fontconfig hasn't been preloaded with the font paths it would
-- need. If that's the case, just skip even defining these tests and call it
-- good. To test a complete set of tests use `make busted`.
local fcf = os.getenv("FONTCONFIG_FILE")
if not fcf then
   return
end

describe("The OpenType loader/parser", function ()
   local ot = require("core.opentype-parser")
   local face = SILE.shaper.getFace({ family = "Libertinus Serif" })
   local font = ot.parseFont(face)

   it("should convert Microsoft-platform name strings to UTF8", function ()
      local version = font.names[5]["en-US"][1]
      assert.is.equal("Version 7.050;RELEASE", version)
   end)
end)

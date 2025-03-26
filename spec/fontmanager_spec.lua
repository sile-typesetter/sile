SILE = require("core.sile")
SILE.input.backend = "debug"
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

describe("The fontconfig manager", function ()
   SILE.input.fontmanager = "fontconfig"

   it("should load a font", function ()
      local family = "Libertinus Serif"
      local face = SILE.shaper.getFace({ family = family })
      assert.is.equal(family, face.family)
   end)

   -- Disable running this test unless we have font variation support. The test itself does not need the feature, but we
   -- have *fonts* in the test data set that do and fontconfig is not deterministic about which fallback we might get
   -- for an unknown font. In this case a font that needs variation support is being returned in some CI environments
   -- when we request this unknown one.
   if SILE.features.font_variations then
      it("should fallback when it can't find a face", function ()
         local family = "Yesteryear Imagination"
         local face
         assert.has_no.errors(function ()
            face = SILE.shaper.getFace({ family = family })
         end)
         assert.is_not.equal(family, face.family)
      end)
   end
end)

describe("The macfonts manager", function ()
   if not SILE.fontManager.macfonts then
      return
   end

   it("should load a font", function ()
      local family = "Libertinus Serif"
      local face = SILE.shaper.getFace({ family = family })
      assert.is.equal(family, face.family)
   end)

   it("should fallback to fontconfig when it fails", function ()
      local family = "Yesteryear Imagination"
      local face
      assert.has_no.errors(function ()
         face = SILE.shaper.getFace({ family = family })
      end)
      assert.is_not.equal(family, face.family)
   end)
end)

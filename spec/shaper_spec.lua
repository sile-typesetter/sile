SILE = require("core.sile")
SILE.input.backend = "debug"
SILE.init()

describe("SILE.shapers.default", function ()
   require("classes.plain")({})

   it("should always have positive stretch and shrink", function ()
      SILE.settings:set("shaper.variablespaces", true)
      SILE.settings:set("shaper.spacestretchfactor", 2)
      SILE.settings:set("shaper.spaceshrinkfactor", 2)
      local negative_glue = SILE.types.node.glue("-4pt")
      local space = SILE.shaper:makeSpaceNode({}, negative_glue)
      assert.is.truthy(space.width.stretch > SILE.types.measurement(0))
      assert.is.truthy(space.width.shrink > SILE.types.measurement(0))
   end)

   describe("measureChar", function ()
      SILE.settings:set("font.family", "Libertinus Serif", true)

      it("should measure simple characters", function ()
         local measurements, found = SILE.shaper:measureChar("a")
         assert.is.truthy(found)
         assert.is.truthy(measurements.width > 0)
         assert.is.truthy(measurements.height > 0)
      end)

      it("should measure multiple characters", function ()
         local measurements, found = SILE.shaper:measureChar("ab")
         assert.is.truthy(found)
         assert.is.truthy(measurements.width > 0)
         assert.is.truthy(measurements.height > 0)
         -- Composite character should be taller than base character
         assert.is.truthy(measurements.width > SILE.shaper:measureChar("a").width)
      end)

      -- TODO, we also need a test for composite characters, but I couldn't find one in our test fonts
      -- it("should measure composite characters", function ()
      --    local measurements, found = SILE.shaper:measureChar("â")
      --    assert.is.truthy(found)
      --    assert.is.truthy(measurements.width > 0)
      --    assert.is.truthy(measurements.height > 0)
      --    -- Composite character should be taller than base character
      --    assert.is.truthy(measurements.height > SILE.shaper:measureChar("a").height)
      -- end)
   end)
end)

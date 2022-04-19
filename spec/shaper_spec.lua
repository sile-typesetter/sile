SILE = require("core/sile")
SILE.backend = "debug"
SILE.init()

describe("SILE.shapers.base", function()

  it("should always have positive stretch and shrink", function()
    SILE.settings.set("shaper.variablespaces", true)
    SILE.settings.set("shaper.spacestretchfactor", 2)
    SILE.settings.set("shaper.spaceshrinkfactor", 2)
    local negative_glue = SILE.nodefactory.glue("-4pt")
    local space = SILE.shaper:makeSpaceNode({}, negative_glue)
    assert.is.truthy(space.width.stretch > SILE.measurement(0))
    assert.is.truthy(space.width.shrink > SILE.measurement(0))
  end)

end)

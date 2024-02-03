SILE = require("core.sile")

describe("The settings handler", function()

  it("should trigger callbacks on set", function()
    local private = "foo"
    local function callback (value)
       private = value .. " hooked"
    end
    SILE.settings:declare({
       parameter = "test.callback",
       type = "string",
       default = "bar",
       hook = callback
    })
    SILE.settings:set("test.callback", "baz")
    assert.is.equal("baz hooked", private)
  end)

  it("should trigger callbacks on push/pop events", function()
    local mystate = "foo"
    local function callback2 (value)
       mystate = value .. " stack"
    end
    SILE.settings:declare({
       parameter = "test.callback2",
       type = "string",
       default = "bar",
       hook = callback2
    })
    SILE.settings:pushState()
    SILE.settings:set("test.callback2", "baz1")
    SILE.settings:pushState()
    SILE.settings:set("test.callback2", "baz2")
    assert.is.equal("baz2 stack", mystate)
    SILE.settings:popState()
    assert.is.equal("baz1 stack", mystate)
    SILE.settings:popState()
    assert.is.equal("bar stack", mystate)
  end)

end)

SILE = require("core.sile")
SILE.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#Markdown #inputter", function ()
  local inputter = SILE.inputters.markdown()

  describe("should parse", function ()

    it("headers", function()
      local t = inputter:parse("# foo bar\n")[1][1][1][1]
      assert.is.equal("chapter", t.command)
      assert.is.same({ "foo bar" }, t[1])
    end)

    it("inline markup", function()
      local t = inputter:parse("foo *bar* or **baz**")[1][1][1][1]
      assert.is.equal("foo ", t[1])
      assert.is.equal("em", t[2].command)
      assert.is.same({ "bar" }, t[2][1])
      assert.is.equal(" or ", t[3])
      assert.is.equal("strong", t[4].command)
      assert.is.same({ "baz" }, t[4][1])
    end)

  end)

  describe("should reject", function ()

  end)

end)



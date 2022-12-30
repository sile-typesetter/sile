SILE = require("core.sile")
SILE.backend = "dummy"
SILE.init()
SILE.utilities.error = error

describe("#SIL #inputter", function ()
  local inputter = SILE.inputters.sil()

  describe("should parse", function ()

    it("commands with content", function()
      local t = inputter:parse([[\foo{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands without content", function()
      local t = inputter:parse([[\foo{\foo bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("foo", t[1][1].command)
      assert.is.equal(" bar", t[1][2])
      assert.is.equal(nil, t[1][1][1])
    end)

    it("commands with arg", function()
      local t = inputter:parse([[\foo[baz=qiz]{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with multiple args", function()
      local t = inputter:parse([[\foo[baz=qiz,qiz=baz]{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz", t.options.baz)
      assert.is.equal("baz", t.options.qiz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with quoted arg", function()
      local t = inputter:parse([[\foo[baz="qiz qiz"]{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz qiz", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with multiple quoted args", function()
      local t = inputter:parse([[\foo[baz="qiz, qiz",qiz="baz, baz"]{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz, qiz", t.options.baz)
      assert.is.equal("baz, baz", t.options.qiz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with quoted arg with escape", function()
      local t = inputter:parse([[\foo[baz="qiz \"qiz\""]{bar}]])[1][1][1]
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz \"qiz\"", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

  end)

  describe("should reject", function ()

    it("commands with bad characters", function()
      assert.has_error(function() inputter:parse([[\"]]) end,
        "parse error, Unexpected character at end of input\n\\\"\n^")
      assert.has_error(function() inputter:parse([[\']]) end,
        "parse error, Unexpected character at end of input\n\\'\n^")
      assert.has_error(function() inputter:parse([[\"o]]) end,
        "parse error, Unexpected character at end of input\n\\\"o\n^")
    end)

    it("commands with unclosed content", function()
      assert.has_error(function() inputter:parse([[\foo{bar]]) end,
        "parse error at <eof>, } expected")
    end)

    it("unclosed environments", function()
      assert.has_error(function() inputter:parse([[\begin{foo}bar]]) end,
        "parse error at <eof>, Environment begun but never ended")
    end)

    it("mismatched environments", function()
      assert.has_error(function() inputter:parse([[\begin{foo}\begin{bar}baz\end{foo}\end{bar}]]) end,
        "parse error, Environment mismatch\n\\begin{foo}\\begin{bar}baz\\end{foo}\\end{bar}\n                              ^")
    end)

  end)
end)

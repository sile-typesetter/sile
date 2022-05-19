SILE = require("core.sile")

describe("#TeXlike #input parser", function ()
  local parse = SILE.inputs.TeXlike.docToTree

  describe("should handle", function ()

    it("commands with content", function()
      local t = parse([[\foo{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with arg", function()
      local t = parse([[\foo[baz=qiz]{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with multiple args", function()
      local t = parse([[\foo[baz=qiz,qiz=baz]{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz", t.options.baz)
      assert.is.equal("baz", t.options.qiz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with quoted arg", function()
      local t = parse([[\foo[baz="qiz qiz"]{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz qiz", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with multiple quoted args", function()
      local t = parse([[\foo[baz="qiz, qiz",qiz="baz, baz"]{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz, qiz", t.options.baz)
      assert.is.equal("baz, baz", t.options.qiz)
      assert.is.equal("bar", t[1][1])
    end)

    it("commands with quoted arg with escape", function()
      local t = parse([[\foo[baz="qiz \"qiz\""]{bar}]])
      assert.is.equal("foo", t.command)
      assert.is.equal("qiz \"qiz\"", t.options.baz)
      assert.is.equal("bar", t[1][1])
    end)

  end)

  describe("should reject", function ()

    it("commands with bad characters", function()
      assert.has.error(function() parse([[\"]]) end)
      assert.has.error(function() parse([[\']]) end)
      assert.has.error(function() parse([[\"o]]) end)
    end)

    it("commands with unclosed content", function()
      assert.has.error(function() parse([[\foo{bar]]) end)
    end)

    it("unclosed environments", function()
      assert.has.error(function() parse([[\begin{foo}bar]]) end)
    end)

    it("mismatched environments", function()
      assert.has.error(function() parse([[\begin{foo}\begin{bar}baz\end{foo}\end{bar}]]) end)
    end)

  end)
end)

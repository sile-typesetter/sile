SILE = require("core/sile")

describe("#TeXlike #input", function ()
  local toTree = SILE.inputs.TeXlike.docToTree

  it("command with content", function()
    local t = toTree([[\foo{bar}]])
    assert.is.equal("foo", t.command)
    assert.is.equal("bar", t[1][1])
  end)

  it("command with arg", function()
    local t = toTree([[\foo[baz=qiz]{bar}]])
    assert.is.equal("qiz", t.options.baz)
    assert.is.equal("bar", t[1][1])
  end)

  it("command with multiple args", function()
    local t = toTree([[\foo[baz=qiz,qiz=baz]{bar}]])
    assert.is.equal("qiz", t.options.baz)
    assert.is.equal("baz", t.options.qiz)
    assert.is.equal("bar", t[1][1])
  end)

  it("command with quoted arg", function()
    local t = toTree([[\foo[baz="qiz qiz"]{bar}]])
    assert.is.equal("qiz qiz", t.options.baz)
    assert.is.equal("bar", t[1][1])
  end)

  it("command with multiple quoted args", function()
    local t = toTree([[\foo[baz="qiz, qiz",qiz="baz, baz"]{bar}]])
    assert.is.equal("qiz, qiz", t.options.baz)
    assert.is.equal("baz, baz", t.options.qiz)
    assert.is.equal("bar", t[1][1])
  end)

  it("command with quoted arg with escape", function()
    local t = toTree([[\foo[baz="qiz \"qiz\""]{bar}]])
    assert.is.equal("qiz \"qiz\"", t.options.baz)
    assert.is.equal("bar", t[1][1])
  end)

end)

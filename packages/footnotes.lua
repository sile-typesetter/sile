-- Footnotes class
SILE.require("packages/counters")
SILE.require("packages/raiselower")
local insertions = SILE.require("packages/insertions")
SILE.scratch.counters.footnote = { value= 1, display= "arabic" };

SILE.registerCommand("footnote", function(options, content)
  SILE.Commands["raise"]({height = "1ex"}, function()
    SILE.Commands["font"]({ size = "2ex" }, function()
      SILE.typesetter:typeset(SILE.scratch.counters.footnote.value)
    end)
  end)
  insertions.exports:insert("footnote", SILE.Commands["vbox"]({}, function()
    SILE.Commands["font"]({size = "9pt"}, function()
      SILE.typesetter:typeset(SILE.scratch.counters.footnote.value..". ")
      SILE.process(content)
    end)
  end
  ))
  SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
end)

return {
  init = function (class, args)
    insertions.exports:initInsertionClass("footnote", { 
    insertInto = args.insertInto,
    stealFrom = args.stealFrom,
    maxHeight = SILE.length.new({length = SILE.toPoints("25", "%","h") }),
    topSkip = SILE.length.parse("4ex")
  })
  end,
  exports = {
    outputInsertions = insertions.exports.outputInsertions
  }
}
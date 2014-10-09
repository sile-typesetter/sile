-- Footnotes class

-- Exports: The \footnote command
--          outputInsertions (call this in endPage)

SILE.require("packages/counters")
SILE.require("packages/raiselower")
local insertions = SILE.require("packages/insertions")
SILE.scratch.counters.footnote = { value= 1, display= "arabic" };

SILE.registerCommand("footnotemark", function(options, content)
  SILE.Commands["raise"]({height = "0.7ex"}, function()
    SILE.Commands["font"]({ size = "1.5ex" }, function()
      SILE.typesetter:typeset(SILE.scratch.counters.footnote.value)
    end)
  end)
end)

SILE.registerCommand("footnote", function(options, content)
  SILE.call("footnotemark")
  -- XXX We need to vbox the material in the context of the frame it's going to
  -- be inserted into, not in the frame it's coming from; e.g. when a two-column
  -- layout has a full-width footnotes frame.
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
    topSkip = SILE.length.parse("12pt")
  })
  end,
  exports = {
    outputInsertions = insertions.exports.outputInsertions
  }
}
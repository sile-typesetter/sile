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
      SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.footnote))
    end)
  end)
end)

SILE.registerCommand("footnote", function(options, content)
  SILE.call("footnotemark")
  local opts = SILE.scratch.insertions.classes.footnote
  local f = SILE.getFrame(opts["insertInto"])
  local oldF = SILE.typesetter.frame
  SILE.typesetter.frame = f
  SILE.typesetter:pushState()
  SILE.typesetter:initFrame(f)
  insertions.exports:insert("footnote", SILE.Commands["vbox"]({}, function()
    SILE.Commands["font"]({size = "9pt"}, function()
      SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.footnote)..".")
      SILE.call("qquad")
      SILE.process(content)
    end)
  end
  ))
  SILE.typesetter:popState()
  SILE.typesetter.frame = oldF
  SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
end)

return {
  init = function (class, args)
    insertions.exports:initInsertionClass("footnote", { 
    insertInto = args.insertInto,
    stealFrom = args.stealFrom,
    maxHeight = SILE.length.new({length = SILE.toPoints("25", "%","h") }),
    topSkip = SILE.length.parse("2ex"),
    interInsertionSkip = SILE.length.parse("1ex"),
  })
  end,
  exports = {
    outputInsertions = insertions.exports.outputInsertions
  }
}
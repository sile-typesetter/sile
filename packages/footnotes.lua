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

SILE.registerCommand("footnote:separator", function(options, content)
  SILE.settings.pushState()
  local material = SILE.Commands["vbox"]({}, content)
  SILE.scratch.insertions.classes.footnote.topBox = material
  SILE.settings.popState()
end)

SILE.registerCommand("footnote:options", function(options, content)
  if options["max-height"] then
    SILE.scratch.insertions.classes.footnote.maxHeight = SILE.length.parse(options["max-height"])
  end
  if options["inter-insertion-skip"] then
    SILE.scratch.insertions.classes.footnote.interInsertionSkip = SILE.length.parse(options["inter-insertion-skip"])
  end
end)

SILE.registerCommand("footnote", function(options, content)
  SILE.call("footnotemark")
  local opts = SILE.scratch.insertions.classes.footnote
  local f = SILE.getFrame(opts["insertInto"])
  local oldT = SILE.typesetter
  SILE.typesetter = SILE.typesetter {}
  SILE.typesetter:init(f)
  SILE.typesetter.pageTarget = function () return 0xFFFFFF end
  SILE.settings.pushState()
  SILE.settings.reset()
  local material = SILE.Commands["vbox"]({}, function()
    SILE.Commands["font"]({size = "9pt"}, function()
      SILE.call("footnote:atstart")
      SILE.call("footnote:counter")
      SILE.process(content)
    end)
  end)
  SILE.settings.popState()
  SILE.typesetter = oldT
  insertions.exports:insert("footnote", material)
  SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
end)

SILE.registerCommand("footnote:atstart", function(o,c)
end)

SILE.registerCommand("footnote:counter", function(o,c)
  SILE.call("noindent")
  SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.footnote)..".")
  SILE.call("qquad")
end)

return {
  init = function (class, args)
    insertions.exports:initInsertionClass("footnote", {
    insertInto = args.insertInto,
    stealFrom = args.stealFrom,
    maxHeight = SILE.length.new({length = SILE.toPoints("75", "%","h") }),
    topBox = SILE.nodefactory.newVglue({height = SILE.length.parse("2ex") }),
    interInsertionSkip = SILE.length.parse("1ex"),
  })
  end,
  exports = {
    outputInsertions = insertions.exports.outputInsertions
  }
}

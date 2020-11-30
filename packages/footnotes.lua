-- Footnotes class

-- Exports: The \footnote command
--          outputInsertions (call this in endPage)

SILE.require("packages/counters")
SILE.require("packages/raiselower")
local insertions = SILE.require("packages/insertions")
SILE.scratch.counters.footnote = { value= 1, display= "arabic" }

SILE.registerCommand("footnotemark", function (_, _)
  SILE.call("raise", { height = "0.7ex" }, function ()
    SILE.call("font", { size = "1.5ex" }, function ()
      SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.footnote))
    end)
  end)
end)

SILE.registerCommand("footnote:separator", function (_, content)
  SILE.settings.pushState()
  local material = SILE.call("vbox", {}, content)
  SILE.scratch.insertions.classes.footnote.topBox = material
  SILE.settings.popState()
end)

SILE.registerCommand("footnote:options", function (options, _)
  if options["maxHeight"] then
    SILE.scratch.insertions.classes.footnote.maxHeight = SILE.length(options["maxHeight"])
  end
  if options["interInsertionSkip"] then
    SILE.scratch.insertions.classes.footnote.interInsertionSkip = SILE.length(options["interInsertionSkip"])
  end
end)

SILE.registerCommand("footnote", function (options, content)
  SILE.call("footnotemark")
  local opts = SILE.scratch.insertions.classes.footnote
  local f = SILE.getFrame(opts["insertInto"].frame)
  local oldT = SILE.typesetter
  SILE.typesetter = SILE.typesetter {}
  SILE.typesetter:init(f)
  SILE.typesetter.getTargetLength = function () return SILE.length(0xFFFFFF) end
  SILE.settings.pushState()
  SILE.settings.reset()
  local material = SILE.call("vbox", {}, function ()
    SILE.call("footnote:font", {}, function ()
      SILE.call("footnote:atstart", options)
      SILE.call("footnote:counter", options)
      SILE.process(content)
    end)
  end)
  SILE.settings.popState()
  SILE.typesetter = oldT
  insertions.exports:insert("footnote", material)
  SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
end)

SILE.registerCommand("footnote:font", function (_, content)
  SILE.call("font", { size = "9pt" }, function ()
    SILE.process(content)
  end)
end)

SILE.registerCommand("footnote:atstart", function (_, _)
end)

SILE.registerCommand("footnote:counter", function (_, _)
  SILE.call("noindent")
  SILE.typesetter:typeset(SILE.formatCounter(SILE.scratch.counters.footnote) .. ".")
  SILE.call("qquad")
end)

return {
  init = function (_, args)
    args = args or {}
    insertions.exports:initInsertionClass("footnote", {
        insertInto = args.insertInto or "footnotes",
        stealFrom = args.stealFrom or { "content" },
        maxHeight = SILE.length("75%ph"),
        topBox = SILE.nodefactory.vglue("2ex"),
        interInsertionSkip = SILE.length("1ex"),
      })
  end,
  exports = {
    outputInsertions = insertions.exports.outputInsertions
  },
  documentation = [[
\begin{document}
We’ve seen that the \code{book} class allows you to add
footnotes to text with the \code{\\footnote} command. This command is
actually provided by the \code{footnotes} package. The \code{book}
class loads up the package and tells it where to put the footnotes
that are typeset, and the \code{footnotes} package takes care of
formatting the footnotes. It does this by using a number of other
packages that we will describe below.
\end{document}
]]
}

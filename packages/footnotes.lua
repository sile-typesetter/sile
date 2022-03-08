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
  -- Restore the settings to the top of the queue, which should be the document #986
  SILE.settings.toplevelState()

  -- Reset settings the document may have but should not be applied to footnotes
  -- See also same resets in folio package
  for _, v in ipairs({
    "current.hangAfter",
    "current.hangIndent",
    "linebreak.hangAfter",
    "linebreak.hangIndent" }) do
    SILE.settings.set(v, SILE.settings.defaults[v])
  end

  -- Apply the font before boxing, so relative baselineskip applies #1027
  local material
  SILE.call("footnote:font", {}, function ()
      material = SILE.call("vbox", {}, function ()
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
  -- The footnote frame has is settings reset to the toplevel state, so if one does
  -- something relative (as below), it is expected to be the main value from the
  -- document.
  SILE.call("font", { size = SILE.settings.get("font.size") * 0.9 }, function ()
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
footnotes to text with the \autodoc:command{\footnote} command. This command is
actually provided by the \autodoc:package{footnotes} package. The \code{book}
class loads up the package and tells it where to put the footnotes
that are typeset, and the \autodoc:package{footnotes} package takes care of
formatting the footnotes. It does this by using a number of other
packages that we will describe below.
\end{document}
]]
}

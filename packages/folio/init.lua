local function _incrementFolio (_)
  SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
end

local function _outputFolio (class, frame)
  if not frame then frame = "folio" end
  local folio = class:formatCounter(SILE.scratch.counters.folio)
  io.stderr:write("[" .. folio .. "] ")
  if SILE.scratch.counters.folio.off then
    if SILE.scratch.counters.folio.off == 2 then
      SILE.scratch.counters.folio.off = false
    end
  else
    local folioFrame = SILE.getFrame(frame)
    if (folioFrame) then
      SILE.typesetNaturally(folioFrame, function ()
        SILE.settings:pushState()
        -- Restore the settings to the top of the queue, which should be the document #986
        SILE.settings:toplevelState()

        -- Reset settings the document may have but should not be applied to footnotes
        -- See also same resets in footnote package
        for _, v in ipairs({
          "current.hangAfter",
          "current.hangIndent",
          "linebreak.hangAfter",
          "linebreak.hangIndent" }) do
          SILE.settings:set(v, SILE.settings.defaults[v])
        end

        SILE.call("foliostyle", {}, { class:formatCounter(SILE.scratch.counters.folio) })
        SILE.typesetter:leaveHmode()
        SILE.settings:popState()
      end)
    end
  end
end

local function init (class, _)
  class:loadPackage("counters")
  SILE.scratch.counters.folio = { value = 1, display = "arabic" }
  class:registerHook("newpage", _incrementFolio)
  class:registerHook("endpage", _outputFolio)
end

local function registerCommands (_)

  SILE.registerCommand("folios", function (_, _)
    SILE.scratch.counters.folio.off = false
  end)

  SILE.registerCommand("nofolios", function (_, _)
    SILE.scratch.counters.folio.off = true
  end)

  SILE.registerCommand("nofoliothispage", function (_, _)
    SILE.scratch.counters.folio.off = 2
  end)

  SILE.registerCommand("nofoliosthispage", function (_, _)
    SU.deprecated("nofoliosthispage", "nofoliothispage", "0.12.1", "0.14.0")
    return SILE.Commands["nofoliothispage"]()
  end, "Deprecated")

  SILE.registerCommand("foliostyle", function (_, content)
    SILE.call("center", {}, content)
  end)

end

local _deprecate  = [[
  Directly calling folio handling functions is no longer necessary. All the
  SILE core classes and anything inheriting from them will take care of this
  automatically using hooks. Custom classes that override the class:endPage()
  and class:finish() functions may need to handle this in other ways. By
  calling these hooks directly you are likely causing them to run twice and
  duplicate entries.
]]

return {
  init = init,
  registerCommands = registerCommands,
  exports = {
    outputFolio = function (class)
      SU.deprecated("class:outputFolio", nil, "0.13.0", "0.14.0", _deprecate)
      return _outputFolio(class)
    end,
  },
  documentation= [[
\begin{document}
The \autodoc:package{folio} package (which is automatically loaded by the
plain class, and therefore by nearly every SILE class) controls
the output of folios—the old-time typesetter word for page numbers.

It provides four commands to users:

\noindent{}• \autodoc:command{\nofolios}: turns page numbers off.

\noindent{}• \autodoc:command{\nofoliothispage}: turns page numbers off for one page, then on again afterward.

\noindent{}• \autodoc:command{\folios}: turns page numbers back on.

\noindent{}• \autodoc:command{\foliostyle}: a command you can override to style the page numbers. By default, they are centered on the page.

If, for instance, you want to set page numbers in a different font
you can redefine the command like so:

\begin{verbatim}
\line
\\define[command=foliostyle]\{\\center\{\\font[family=Albertus]\{\\process\}\}\}
\line
\end{verbatim}

If you want to put page numbers on the left side of even pages and the
right side of odd pages, there are a couple of ways you can do that. The
complicated way is to define a command in Lua which inspects the page number
and then sets the number ragged left or ragged right appropriately. The easy
way is just to put your folio frame where you want it on the master page...
\end{document}
]]
}

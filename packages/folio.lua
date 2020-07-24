-- Folios class
SILE.require("packages/counters")

SILE.scratch.counters.folio = { value = 1, display = "arabic" }

SILE.registerCommand("folios", function (_, _)
  SILE.scratch.counters.folio.off = false
end)

SILE.registerCommand("nofolios", function (_, _)
  SILE.scratch.counters.folio.off = true
end)

SILE.registerCommand("nofoliosthispage", function (_, _)
  SILE.scratch.counters.folio.off = 2
end)

SILE.registerCommand("foliostyle", function (_, content)
  SILE.call("center", {}, content)
end)

return {
  init = function () end,
  exports = {

    outputFolio = function (_, frame)
      if not frame then frame = "folio" end
      io.stderr:write("[" .. SILE.formatCounter(SILE.scratch.counters.folio) .. "] ")
      if SILE.scratch.counters.folio.off then
        if SILE.scratch.counters.folio.off == 2 then
          SILE.scratch.counters.folio.off = false
        end
      else
        local folioFrame = SILE.getFrame(frame)
        if (folioFrame) then
          SILE.typesetNaturally(folioFrame, function ()
            SILE.settings.pushState()
            SILE.settings.reset()
            SILE.call("foliostyle", {}, { SILE.formatCounter(SILE.scratch.counters.folio) })
            SILE.typesetter:leaveHmode()
            SILE.settings.popState()
          end)
        end
      end
      SILE.scratch.counters.folio.value = SILE.scratch.counters.folio.value + 1
    end
  },
  documentation= [[
\begin{document}
The \code{folio} package (which is automatically loaded by the
plain class, and therefore by nearly every SILE class) controls
the output of folios - the old-time typesetter word for page numbers.

It provides four commands to users:

\noindent{}• \code{\\nofolios}: turns page numbers off.

\noindent{}• \code{\\nofoliothispage}: turns page numbers off for one page, then on again afterward.

\noindent{}• \code{\\folios}: turns page numbers back on.

\noindent{}• \code{\\foliostyle}: a command you can override to style the page numbers. By default, they are centered on the page.

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

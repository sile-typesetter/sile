SILE.registerCommand("verbatim:font", function(options, content)
    SILE.settings.set("font.family", "Consolas")
    SILE.settings.set("font.size", SILE.settings.get("font.size") - 3)
end, "The font chosen for the verbatim environment")

SILE.registerCommand("verbatim", function(options, content)
  SILE.typesetter:pushVglue({ height = SILE.length.new({ length = 6 }) })
  SILE.typesetter:leaveHmode()
  SILE.settings.temporarily(function()
    SILE.settings.set("typesetter.parseppattern", "\n")
    SILE.settings.set("typesetter.obeyspaces", true)
    SILE.settings.set("document.rskip", SILE.nodefactory.newGlue("0 plus 10000pt"))
    SILE.settings.set("document.parindent", SILE.nodefactory.newGlue("0"))
    SILE.settings.set("document.baselineskip", SILE.nodefactory.newVglue("0"))
    SILE.settings.set("document.lineskip", SILE.nodefactory.newVglue("2pt"))
    SILE.call("verbatim:font")
    SILE.settings.set("document.spaceskip", SILE.length.parse("1spc"))
    SILE.settings.set("shaper.variablespaces",0)
    SILE.settings.set("document.language", "und")
    -- SILE.settings.set("shaper.spacepattern", '%s') -- XXX Shaper no longer uses this so it was removed
    SILE.process(content)
  end)
  SILE.typesetter:leaveHmode()
end, "Typesets its contents in a monospaced font.")

SILE.registerCommand("obeylines", function(options, content)
  SILE.settings.temporarily(function()
    SILE.settings.set("typesetter.parseppattern", "\n")
    SILE.process(content)
  end)
end)

return [[\begin{document}

The \code{verbatim} package is useful when quoting pieces of computer code and
other text for which formatting is significant. It changes SILE’s settings
so that text is set ragged right, with no hyphenation, no indentation and
regular spacing. It tells SILE to honor multiple spaces, and sets a monospaced
font.

\note{Despite the name, \code{verbatim} does not alter the way that SILE
sees special characters. You still need to escape backslashes and braces:
to produce a backslash, you need to write \code{\\\\}.}

Here is some text set in the verbatim environment:

\begin{verbatim}
function SILE.repl()
  if not SILE._repl then SILE.initRepl() end
  SILE._repl:run()
end
\end{verbatim}

If you want to specify what font the verbatim environment should use, you
can redefine the \code{verbatim:font} command. The current document says:

\begin{verbatim}
<define command="verbatim:font">
   <font family="DejaVu Sans Mono" size="9pt"/>
</define>
\end{verbatim}
\end{document}]]

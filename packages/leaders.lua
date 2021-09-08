local leader = pl.class({
    _base = SILE.nodefactory.glue,

    outputYourself = function (self, typesetter, line)
      local outputWidth = SU.rationWidth(self.width, self.width, line.ratio)
      local valwidth = self.value.width
      local repetitions = math.floor(outputWidth:tonumber() / valwidth:tonumber())
      if repetitions < 1 then
        typesetter.frame:advanceWritingDirection(outputWidth)
        return
      end
      local remainder = outputWidth - repetitions * valwidth
      if repetitions == 1 then
        typesetter.frame:advanceWritingDirection(remainder / 2)
        self.value:outputYourself(typesetter, line)
        typesetter.frame:advanceWritingDirection(remainder / 2)
      end
      if repetitions > 1 then
        local glue = remainder / (repetitions + 1)
        typesetter.frame:advanceWritingDirection(glue)
        for _ = 1, repetitions do
          self.value:outputYourself(typesetter, line)
          typesetter.frame:advanceWritingDirection(glue)
        end
      end
    end

  })

SILE.registerCommand("leaders", function(options, content)
  local width = SU.required(options, "width", "creating leaders", "length")
  SILE.call("hbox", {}, content)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  local l = leader({ width = width, value = hbox })
  table.insert(SILE.typesetter.state.nodes, l)
end)

SILE.registerCommand("dotfill", function(_, _)
  SILE.call("leaders", { width = "0pt plus 100000pt" }, function()
    SILE.call("kern", { width = "1spc" })
    SILE.typesetter:typeset(".")
    SILE.call("kern", { width = "1spc" })
    end)
end)

return {
  documentation = [[
\begin{document}
The leaders package allows you to create repeating patterns which fill a
given space. It provides the \code{\\dotfill} command, which does this:

\begin{verbatim}
\line
A \\dotfill B
\line
\end{verbatim}

\begin{examplefont}
A \dotfill B
\end{examplefont}

It also provides the \code{\\leaders[width=...]\{content\}} command which
allow you to define your own leaders. For example:

\begin{verbatim}
\line
A \\leaders[width=40pt]\{/\\\\\} B
\line
\end{verbatim}

\begin{examplefont}
A \leaders[width=40pt]{/\\} B
\end{examplefont}

\end{document}
]]
}

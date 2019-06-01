local leader = SILE.nodefactory.newGlue({})
leader.outputYourself = function (self,typesetter, line)
  local scaledWidth = self.width.length
  if line.ratio and line.ratio < 0 and self.width.shrink > 0 then
    scaledWidth = scaledWidth + self.width.shrink * line.ratio
  elseif line.ratio and line.ratio > 0 and self.width.stretch > 0 then
    scaledWidth = scaledWidth + self.width.stretch * line.ratio
  end
  local valwidth = self.value.width.length
  local repetitions = math.floor(scaledWidth / valwidth)
  if repetitions < 1 then
    typesetter.frame:advanceWritingDirection(scaledWidth)
    return
  end

  local remainder = scaledWidth - repetitions * valwidth
  if repetitions == 1 then
    typesetter.frame:advanceWritingDirection(remainder)
    self.value:outputYourself(typesetter, line)
  end

  if repetitions > 1 then
    local glue = remainder / (repetitions-1)
    for i=1,(repetitions-1) do
      self.value:outputYourself(typesetter, line)
      typesetter.frame:advanceWritingDirection(glue)
    end
    self.value:outputYourself(typesetter, line)
  end
end

SILE.registerCommand("leaders", function(o,c)
  local gluespec = SU.required(o, "width", "creating leaders")
  local width = SILE.length.parse(gluespec)
  SILE.call("hbox", {}, c)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  local l = leader({ width = width, value = hbox })
  table.insert(SILE.typesetter.state.nodes, l)
end)

SILE.registerCommand("dotfill", function(o,c)
  SILE.call("leaders", {width = "0pt plus 100000pt"}, {" . "})
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
A \\leaders[width=30pt]\{\\font[features="+ornm"]{iI}\} B
\line
\end{verbatim}

\begin{examplefont}
A \leaders[width=40pt]{\font[features="+ornm"]{iI}} B
\end{examplefont}

\end{document}
]]
}

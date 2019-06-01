SILE.registerCommand("ifattop", function (o, c)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) == 0 then
    SILE.process(c)
  end
end)

SILE.registerCommand("ifnotattop", function (o, c)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) ~= 0 then
    SILE.process(c)
  end
end)

return {
  documentation = [[
\begin{document}
This package provides two commands: \code{\\ifattop} and \code{\\ifnotattop}.
The argument of the command is processed only if the typesetter is at the top
of a frame or is not at the top of a frame respectively.
\end{document}
]]
}

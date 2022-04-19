SILE.registerCommand("debug", function (options, _)
  for k, v in pairs(options) do
    SILE.debugFlags[k] = SU.boolean(v, true)
  end
end)

SILE.registerCommand("disable-pushback", function (_, _)
  SILE.typesetter.pushBack = function() end
end)

return {
documentation = [[
\begin{document}
This package provides two commands: \autodoc:command{\debug}, which turns
on and off SILE’s internal debugging flags (similar to using \code{--debug=...}
on the command line); and \autodoc:command{\disable-pushback} which is used
by SILE’s developers to turn off the typesetter’s pushback routine, because we
don’t really trust it very much.
\end{document}
]]
}

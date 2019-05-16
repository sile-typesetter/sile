SILE.registerCommand("debug", function (options,c)
  for k,v in pairs(options) do
    if v == "false" or v == "no" or v == "off" then
      SILE.debugFlags[k] = false
    else
      SILE.debugFlags[k] = true
    end
  end
end)

SILE.registerCommand("disable-pushback", function (options,c)
  SILE.typesetter.pushBack = function(self) end
end)

return {
documentation = [[\begin{document}
This package provides two commands: \code{debug}, which turns
on and off SILE’s internal debugging flags (similar to using \code{--debug=...}
on the command line); and \code{disable-pushback} which is used
by SILE’s developers to turn off the typesetter’s pushback routine, because we
don’t really trust it very much.
\end{document}
]]
}

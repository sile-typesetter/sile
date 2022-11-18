local base = require("packages.base")

local package = pl.class(base)
package._name = "ifattop"

function package:registerCommands ()

  self:registerCommand("ifattop", function (_, content)
    SILE.typesetter:leaveHmode()
    if #(SILE.typesetter.state.outputQueue) == 0 then
      SILE.process(content)
    end
  end)

  self:registerCommand("ifnotattop", function (_, content)
    SILE.typesetter:leaveHmode()
    if #(SILE.typesetter.state.outputQueue) ~= 0 then
      SILE.process(content)
    end
  end)

end

package.documentation = [[
\begin{document}
This package provides two commands: \autodoc:command{\ifattop} and \autodoc:command{\ifnotattop}.
The argument of the command is processed only if the typesetter is at the top of a frame or is not at the top of a frame respectively.
\end{document}
]]

return package

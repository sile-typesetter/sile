local base = require("packages.base")

local package = pl.class(base)
package._name = "inputfilter"

function package:transformContent (content, transformFunction, extraArgs)
   local newContent = {}
   for k, v in SU.sortedpairs(content) do
      if type(k) == "number" then
         if type(v) == "string" then
            local transformed = transformFunction(v, content, extraArgs)
            if type(transformed) == "table" then
               for i = 1, #transformed do
                  newContent[#newContent + 1] = transformed[i]
               end
            else
               newContent[#newContent + 1] = transformed
            end
         else
            newContent[#newContent + 1] = self:transformContent(v, transformFunction, extraArgs)
         end
      else
         newContent[k] = v
      end
   end
   return newContent
end

function package.createCommand (_, pos, col, lno, command, options, content)
   local position = { lno = lno, col = col, pos = pos }
   return SU.ast.createCommand(command, options, content, position)
end

function package:_init ()
   base._init(self)
end

package.documentation = [[
\begin{document}
The \autodoc:package{inputfilter} package provides ways for class authors to transform the input of a SILE document after it is parsed but before it is processed.
It does this by allowing you to rewrite the abstract syntax tree representing the document.

Loading \autodoc:package{inputfilter} into your class with \code{class:loadPackage("inputfilter")} provides you with two new Lua functions: \code{transformContent} and \code{createCommand}.
\code{transformContent} takes a content tree and applies a transformation function to the text within it.
See \url{https://sile-typesetter.org/examples/inputfilter.sil} for a simple example, and \url{https://sile-typesetter.org/examples/chordmode.sil} for a more complete one.
\end{document}
]]

return package

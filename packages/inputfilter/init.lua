local function transformContent (content, transformFunction, extraArgs)
  local newContent = {}
  for k, v in SU.sortedpairs(content) do
    if type(k) == "number" then
      if type(v) == "string" then
        local transformed = transformFunction(v, content, extraArgs)
        if type(transformed) == "table" then
          for i = 1, #transformed do newContent[#newContent+1] = transformed[i] end
        else
          newContent[#newContent+1] = transformed
        end
      else
        newContent[#newContent+1] = transformContent(v, transformFunction, extraArgs)
      end
    else
      newContent[k] = v
    end
  end
  return newContent
end

local function createCommand (pos, col, line, command, options, content)
  local result = { content }
  result.col = col
  result.line = line
  result.pos = pos
  result.options = options
  result.command = command
  result.id = "command"
  return result
end

return {
  exports = {
    createCommand = createCommand,
    transformContent = transformContent
  },
  documentation = [[\begin{document}
The \autodoc:package{inputfilter} package provides ways for class authors to transform the
input of a SILE document after it is parsed but before it is processed. It does
this by allowing you to rewrite the abstract syntax tree representing the document.

Loading \autodoc:package{inputfilter} into your class with \code{class:loadPackage("inputfilter")}
provides you with two new Lua functions: \code{transformContent} and \code{createCommand}.
\code{transformContent} takes a content tree and applies a transformation function to the
text within it. See \url{https://sile-typesetter.org/examples/inputfilter.sil} for a simple example, and
\code{packages/chordmode.sil} for a more complete one.
\end{document}
]]}

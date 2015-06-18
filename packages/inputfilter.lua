local function tableInsertAll(t, values)
  local i, n
  for i, n in ipairs(values) do
    table.insert(t, n)
  end
end

local function transformContent(content, transformFunction, data)
  local k, v
  local newContent = {}

  for k,v in pairs(content) do
    if type(k) == "number" then
      if type(v) == "string" then
        local nc = transformFunction(v, content, data)
        if type(nc) == "table" then
          tableInsertAll(newContent, nc)
        else
          table.insert(newContent, nc)
        end
      else
        table.insert(newContent, transformContent(v, transformFunction, data))
      end
    else
      newContent[k] = v
    end
  end
  return newContent
end

local function createCommand(pos, col, line, tag, attr, content)
  local result = {content}
  result.col = col
  result.line = line
  result.pos = pos
  result.attr = attr
  result.tag = tag
  result.id = "command"
  return result
end

return {
  exports = {
    createCommand = createCommand,
    transformContent = transformContent
  }, documentation = [[\begin{document}
The \code{inputfilter} package provides ways for class authors to transform the
input of a SILE document after it is parsed but before it is processed. It does
this by allowing you to rewrite the abstract syntax tree representing the document.

Loading \code{inputfilter} into your class with \code{class:loadPackage("inputfilter")}
provides you with two new Lua functions: \code{transformContent} and \code{createCommand}.
\code{transformContent} takes a content tree and applies a transformation function to the
text within it. See \code{examples/inputfilter.sil} for a simple example, and
\code{packages/chordmode.sil} for a more complete one.
\end{document}
]]}

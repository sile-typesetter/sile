local function tableInsertAll(t, values)
  local i, n
  for i, n in ipairs(values) do
    table.insert(t, n)
  end
end

local function transformContent(content, transformFunction)
  local k, v
  local newContent = {}

  for k,v in pairs(content) do 
    if type(k) == "number" then
      if type(v) == "string" then
        local nc = transformFunction(v, content)
        if type(nc) == "table" then
          tableInsertAll(newContent, nc)
        else
          table.insert(newContent, nc)
        end
      else 
        table.insert(newContent, transformContent(v, transformFunction))
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
  }
}

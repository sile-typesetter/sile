local inputfilter = SILE.require("packages/inputfilter").exports

local filter = function (v, content, data)
  if type(v) == "table" then return v end
  local result = {}
  for token in SU.gtoke(v, data) do
    if token.string then
      table.insert(result, token.string)
    else
      table.insert(result, token.separator)
      table.insert(result, inputfilter.createCommand(
        content.pos, content.col, content.line,
        "goodbreak", {}, nil
      ))
    end
  end
  return result
end

SILE.registerCommand("url", function (options,content)
  local breakpat = options.breakpat or "/"
  local result = inputfilter.transformContent(content, filter, breakpat)
  SILE.call("code", {}, result)
end)
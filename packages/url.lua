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
        "penalty", {penalty = 100}, nil
      ))
    end
  end
  return result
end

SILE.require("packages/verbatim")

SILE.registerCommand("url", function (options,content)
  local breakpat = options.breakpat or "/"
  local result = inputfilter.transformContent(content, filter, breakpat)
  SILE.call("code", {}, result)
end)

SILE.registerCommand("code", function(options, content)
  SILE.settings.temporarily(function()
    SILE.call("verbatim:font")
    SILE.process(content)
    SILE.typesetter:typeset(" ")
  end)
end)

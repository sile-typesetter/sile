SILE.require("packages/verbatim")

local inputfilter = SILE.require("packages/inputfilter").exports

local urlFilter = function (node, content, breakpat)
  if type(node) == "table" then return node end
  local result = {}
  for token in SU.gtoke(node, breakpat) do
    if token.string then
      result[#result+1] = token.string
    else
      result[#result+1] = token.separator
      result[#result+1] = inputfilter.createCommand(
        content.pos, content.col, content.line,
        "penalty", { penalty = 100 }, nil
      )
    end
  end
  return result
end

SILE.registerCommand("url", function (options, content)
  local breakpat = options.breakpat or "/"
  local result = inputfilter.transformContent(content, urlFilter, breakpat)
  SILE.call("code", {}, result)
end)

SILE.registerCommand("code", function(options, content)
  SILE.settings.temporarily(function()
    SILE.call("verbatim:font")
    SILE.process(content)
    SILE.typesetter:typeset(" ")
  end)
end)

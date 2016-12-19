SILE.require("packages/verbatim")
local pdf
pcall(function() pdf = require("justenoughlibtexpdf") end)
if pdf then SILE.require("packages/pdf") end

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

SILE.registerCommand("href", function (options, content)
  if not pdf then return SILE.process(content) end
  if options.src then
    SILE.call("pdf:link", { dest = options.src, external = true }, content)
  else
    options.src = content[1]
    local breakpat = options.breakpat or "/"
    content = inputfilter.transformContent(content, urlFilter, breakpat)
    SILE.call("pdf:link", { dest = options.src }, content)
  end
end)

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

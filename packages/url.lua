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
    SILE.call("pdf:link", { dest = options.src, external = true,
      borderwidth = options.borderwidth,
      borderstyle = options.borderstyle,
      bordercolor = options.bordercolor,
      borderoffset = options.borderoffset },
      content)
  else
    options.src = content[1]
    local breakpat = options.breakpat or "/"
    content = inputfilter.transformContent(content, urlFilter, breakpat)
    SILE.call("pdf:link", { dest = options.src, external = true,
      borderwidth = options.borderwidth,
      borderstyle = options.borderstyle,
      bordercolor = options.bordercolor,
      borderoffset = options.borderoffset },
      function (_, _)
        SILE.call("code", {}, content)
      end)
  end
end)

SILE.registerCommand("url", function (options, content)
  local breakpat = options.breakpat or "/"
  local result = inputfilter.transformContent(content, urlFilter, breakpat)
  SILE.call("code", {}, result)
end)

SILE.registerCommand("code", function(options, content)
  SILE.call("verbatim:font", options, content)
end)

return {
  documentation = [[\begin{document}
This package enhances the typesetting of URLs in two ways.
First, the \code{\\url} command will automatically insert breakpoints into unwieldy
URLs like \url{https://github.com/sile-typesetter/sile-typesetter.github.io/tree/master/examples}
so that they can be broken up over multiple lines.

It also provides the
\code{\\href[src=...]\{\}} command which inserts PDF hyperlinks,
\href[src=http://www.sile-typesetter.org/]{like this}.

The \code{\\href} command accepts the same \code{borderwidth}, \code{bordercolor},
\code{borderstyle} and \code{borderoffset} styling options as the \code{\\pdf:link} command
from the \code{pdf} package, for instance
\href[src=http://www.sile-typesetter.org/, borderwidth=0.4pt, bordercolor=blue, borderstyle=underline]{like this}.
\end{document}]]
}

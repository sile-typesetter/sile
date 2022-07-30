local base = require("packages.base")

local package = pl.class(base)
package._name = "xmltricks"

function package:registerCommands ()

  self:registerCommand("xmltricks:ignore", function (_, content)
    for token in SU.gtoke(content[1]) do
      if token.string then SILE.call("define", { command = token.string}, function() end) end
    end
  end)

  self:registerCommand("xmltricks:passthru", function (_, content)
    for token in SU.gtoke(content[1]) do
      if token.string then self:registerCommand(token.string, function(_, c) SILE.process(c) end) end
    end
  end)

end

package.documentation = [[
\begin{document}
In chapter 9, we’re going to use SILE to typeset existing XML documents.
Most of the work of typesetting XML with SILE is creating processing expectations for particular XML tags.
\autodoc:package{xmltricks} makes the process somewhat easier by providing commands to handle two common cases.

\autodoc:command{\xmltricks:ignore{tag1 tag2 tag3}} instructs SILE not to bother investigating the given tags.
For instance, when processing a HTML document, you probably don’t need to typeset the \code{head} tag or anything inside it.

Similarly, some tags are just wrappers; you want to process their content, but there’s nothing specific about the tag itself that needs any styling.
List those tags in a \autodoc:command{\xmltricks:passthru{...}} command, and SILE will descend into the content without requiring a specific command for the tag itself.
\end{document}
]]

return package

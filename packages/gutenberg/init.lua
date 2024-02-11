local base = require("packages.base")

local package = pl.class(base)
package._name = "gutenberg"

function package:registerCommands ()

  self:registerCommand("alt", function (_, _)
    SU.deprecated("\\alt", "\\alternative", "0.10.0", "0.14.0")
  end, "Deprecated")

  self:registerCommand("alternative", function (_, content)
    local alts = {}
    for _, fragment in ipairs(content) do
      local hbox, hlist = SILE.typesetter:makeHbox({ fragment })
      if #hlist > 0 then
        SU.error("Forbidden migrating content in alternative")
      end
      table.insert(alts, hbox)
    end
    local alternative = SILE.types.node.alternative({
      options = alts,
      selected = 1
      })
    alternative.width = nil
    SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = alternative
  end)

end

package.documentation = [[
\begin{document}
Johann Gutenberg’s 42-line Bible is considered a masterpiece of early printing in part due to the quality of justification of every line.
To achieve perfect justification color, Gutenberg used a number of ligatures, abbreviations, substitutions, and so on.

As an experiment in extending SILE’s justification engine, the \autodoc:package{gutenberg} package allows SILE to choose between a number of different options for a particular piece of text, depending on what would improve the line fitting.

For instance, issuing the command \autodoc:command{\alternative{\{and\}\{&\}}} would insert either the text \autodoc:example{and} or an ampersand, depending on what best fits the current line.
\end{document}
]]

return package

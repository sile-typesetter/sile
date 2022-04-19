SILE.registerCommand("alt", function (_, content)
  SU.warn("Use of \\alt  is deprecated, please use \\alternative.")
  SILE.call("alternative", {}, content)
end)

SILE.registerCommand("alternative", function (_, content)
  local options = {}
  for _, fragment in ipairs(content) do
    SILE.call("hbox", {}, { fragment })
    options[#options + 1] = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
    SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  end
  local alternative = SILE.nodefactory.alternative({
    options=options,
    selected=1
    })
  alternative.width=nil
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = alternative
end)

return {
  documentation = [[
\begin{document}
One of the reasons why Johann Gutenberg’s 42 line Bible is considered a
masterpiece of early printing is due to the quality of justification of
every line. To achieve perfect justification color, Gutenberg used a number
of ligatures, abbreviations, substitutions and so on. As an experiment in
extending SILE’s justification engine, the \code{gutenberg} package allows
SILE to choose between a number of different options for a particular
piece of text, depending on what would improve the line fitting.

For instance, issuing the command \autodoc:command{\alternative{\{and\}\{&\}}} would insert
either the text \examplefont{and} or an ampersand, depending on what best
fits the current line.
\end{document}
]]
}

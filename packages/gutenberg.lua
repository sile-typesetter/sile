SILE.registerCommand("alt", function(o, c)
  local options = {}
  for i=1,#c do
    SILE.call("hbox", {}, {c[i]})
    options[#options + 1] = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
    SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
  end
  alt = SILE.nodefactory.newAlternative({
    options=options,
    selected=1
    })
  alt.width=nil
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = alt
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

For instance, issuing the command \code{\\alt\{\{and\}\{&\}\}} would insert
either the text \examplefont{and} or an ampersand, depending on what best
fits the current line.
\end{document}
]]
}

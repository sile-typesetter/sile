SILE.registerCommand("alt", function (_, content)
  SILE.warn("Use of \\alt  is deprecated, please use \\alternative.")
  SILE.call("alternative", nil, content)
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

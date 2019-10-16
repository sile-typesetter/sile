SILE.registerCommand("alt", function (_, content)
  local options = {}
  for _, fragment in ipairs(content) do
    SILE.call("hbox", {}, { fragment })
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

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
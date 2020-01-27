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

local bidi = require("packages/bidi")
SILE.registerCommand("process-jalt", function (_, content)
  local pretty = require("pl.pretty")
  -- Process normally
  local saveTypesetter = SILE.typesetter
  SILE.typesetter = SILE.defaultTypesetter {}
  SILE.typesetter:init(saveTypesetter.frame)
  SILE.process(content)
  SILE.typesetter:shapeAllNodes(SILE.typesetter.state.nodes)
  table.remove(SILE.typesetter.state.nodes,1)
  table.remove(SILE.typesetter.state.nodes,1)
  local nodes1 = SILE.typesetter.state.nodes

  -- Process with +JALT
  SILE.typesetter = SILE.defaultTypesetter {}
  SILE.typesetter:init(saveTypesetter.frame)
  local nodes2
  SILE.settings.temporarily(function ()
    SILE.settings.set("font.features", "+jalt")
    SILE.process(content)
    SILE.typesetter:shapeAllNodes(SILE.typesetter.state.nodes)
    table.remove(SILE.typesetter.state.nodes,1)
    table.remove(SILE.typesetter.state.nodes,1)
    nodes2 = SILE.typesetter.state.nodes
  end)

  -- Check if lengths are different...
  SILE.typesetter = saveTypesetter
  for i = 1,#nodes1 do
    if nodes1[i]:isGlue() or (nodes1[i].width == nodes2[i].width) then
      SILE.typesetter:pushHorizontal(nodes1[i])
    else
     local alt = SILE.nodefactory.newAlternative({
        options= { nodes1[i], nodes2[i] },
        selected=1
        })
      alt.bidiDone = true
      SILE.typesetter:pushHorizontal(alt)
   end
  end
end)


plain = SILE.baseClass { id = "plain" }

plain:declareFrame("a",     {left = "5%",  right = "95%",  top = "5%",  bottom = "90%" });
plain:declareFrame("folio", {left = "5%",  right = "95%",  top = "92%", bottom = "97%" });

plain.pageTemplate.firstContentFrame = plain.pageTemplate.frames["a"];
plain:loadPackage("folio");

plain.endPage = function(self)
  plain:outputFolio()
end

SILE.registerCommand("noindent", function ( options, content )
  SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
  SILE.process(content)
end)

local skips = { small= "3pt plus 1pt minus 1pt", 
      med = "6pt plus 2pt minus 2pt",
      big = "12pt plus 4pt minus 4pt"}

for k,v in pairs(skips) do
  SILE.settings.declare({ 
    name = "plain."..k.."skipamount", type="VGlue", default = SILE.nodefactory.newVglue(v),
    help = "The amount of a \\"..k.."skip"})
  SILE.registerCommand(k.."skip", function ( options, content )
    SILE.typesetter:leaveHmode();    
    SILE.typesetter:pushVglue(SILE.settings.get("plain."..k.."skipamount"))
  end)
end

SILE.registerCommand("hfill", function(o,c) SILE.typesetter:pushGlue(SILE.nodefactory.hfillGlue) end)
SILE.registerCommand("vfill", function(o,c) SILE.typesetter:pushVglue(SILE.nodefactory.vfillGlue) end)
SILE.registerCommand("hss", function(o,c) 
  SILE.typesetter:initline()
  SILE.typesetter:pushGlue(SILE.nodefactory.hssGlue)
  table.insert(SILE.typesetter.state.nodes, SILE.nodefactory.zeroHbox) 
end)
SILE.registerCommand("vss", function(o,c) SILE.typesetter:pushVglue(SILE.nodefactory.vssGlue) end)


SILE.registerCommand("hbox", function (o,c)
  local index = #(SILE.typesetter.state.nodes)+1
  local recentContribution = {}
  SILE.process(c)
  local l = SILE.length.new()
  local h,d = 0,0
  for i = index, #(SILE.typesetter.state.nodes) do
    local node = SILE.typesetter.state.nodes[i]
    table.insert(recentContribution, node)
    l = l + node.width
    h = node.height > h and node.height or h
    d = node.depth > d and node.depth or d
    SILE.typesetter.state.nodes[i] = nil
  end
  local hbox = SILE.nodefactory.newHbox({
    height = h,
    width = l,
    depth = d,
    value = recentContribution,
    outputYourself = function (self, typesetter, line)
      for i = 1, #(self.value) do local node = self.value[i]
        node:outputYourself(typesetter, line)
      end
    end
  })
  table.insert(SILE.typesetter.state.nodes, hbox)
  return hbox
end, "Compiles all the enclosed horizontal-mode material into a single hbox")

return plain;
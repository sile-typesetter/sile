
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
end, "Do not add an indent to the start of this paragraph")

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
  end, "Skip vertically by a "..k.." amount")
end

SILE.registerCommand("hfill", function(o,c) SILE.typesetter:pushGlue(SILE.nodefactory.hfillGlue) end, "Add a huge horizontal glue")
SILE.registerCommand("vfill", function(o,c) 
  SILE.typesetter:leaveHmode()
  SILE.typesetter:pushVglue(SILE.nodefactory.vfillGlue) end, "Add huge vertical glue")
SILE.registerCommand("hss", function(o,c) 
  SILE.typesetter:initline()
  SILE.typesetter:pushGlue(SILE.nodefactory.hssGlue)
  table.insert(SILE.typesetter.state.nodes, SILE.nodefactory.zeroHbox) 
end, "Add glue which stretches and shrinks horizontally (good for centering)")
SILE.registerCommand("vss", function(o,c) SILE.typesetter:pushVglue(SILE.nodefactory.vssGlue) end, "Add glue which stretches and shrinks vertically")

plain.registerCommands = function()
  SILE.baseClass.registerCommands()
  SILE.process(SILE.inputs.TeXlike.docToTree([[\begin{document}%
\define[command=thinspace]{\glue[width=0.16667em]}%
\define[command=negthinspace]{\glue[width=-0.16667em]}%
\define[command=enspace]{\glue[width=0.5em]}%
\define[command=enskip]{\enspace}%
\define[command=quad]{\glue[width=1em]}%
\define[command=qquad]{\glue[width=em]}%
\define[command=slash]{/\penalty[penalty=50]}%
\define[command=break]{\penalty[penalty=-10000]}%
\define[command=framebreak]{\break}%
\define[command=pagebreak]{\penalty[penalty=-20000]}%
\define[command=nobreak]{\penalty[penalty=10000]}%
\define[command=allowbreak]{\penalty[penalty=0]}%
\define[command=filbreak]{\vfill\penalty[penalty=-200]}%
\define[command=goodbreak]{\vfill\penalty[penalty=-500]}%
\define[command=eject]{\par\break}%
\define[command=supereject]{\par\penalty[penalty=-20000]}%
\define[command=raggedright]{\set[parameter=document.rskip,value=0 plus 2em]}%
\define[command=justified]{\set[parameter=document.rskip,value=0]}%
\define[command=em]{\font[style=italic]{\process}}%
\define[command=nohyphenation]{\font[language=xx]{\process}}%
\end{document}
  ]]))
end

SILE.registerCommand("{", function (o,c) SILE.typesetter:typeset("{") end)
SILE.registerCommand("}", function (o,c) SILE.typesetter:typeset("}") end)
SILE.registerCommand("%", function (o,c) SILE.typesetter:typeset("%") end)
SILE.registerCommand("\\", function (o,c) SILE.typesetter:typeset("\\") end)

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

SILE.registerCommand("vbox", function (o,c)
  SILE.typesetter:pushState()
  SILE.process(c)
  SILE.typesetter:leaveHmode()
  local vbox = SILE.pagebuilder.collateVboxes(SILE.typesetter.state.outputQueue)
  SILE.typesetter:popState()
  return vbox
end, "Compiles all the enclosed horizontal-mode material into a single hbox")

return plain;
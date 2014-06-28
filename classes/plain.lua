
plain = SILE.baseClass { id = "plain" }

plain:declareFrame("a",     {left = "5%",  right = "95%",  top = "5%",  bottom = "90%" });
plain:declareFrame("folio", {left = "5%",  right = "95%",  top = "92%", bottom = "97%" });

plain.pageTemplate.firstContentFrame = plain.pageTemplate.frames["a"];
plain:loadPackage("folio");

plain.newPage = function(self)
  plain:outputFolio()
  return SILE.baseClass.newPage(self);
end

SILE.registerCommand("noindent", function ( options, content )
  SILE.settings.temporarily( function ()
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.process(content)
  end)
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
end)
SILE.registerCommand("vss", function(o,c) SILE.typesetter:pushVglue(SILE.nodefactory.vssGlue) end)

return plain;
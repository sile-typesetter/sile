if SILE.outputter ~= SILE.outputters.libtexpdf then
  SU.error("pdf package requires libtexpdf backend")
end
local pdf = require("justenoughlibtexpdf")

SILE.registerCommand("pdf:destination", function (o,c)
  local name = o.name
  SILE.typesetter:pushHbox({ 
    value = nil,
    height = 0,
    width = 0,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.destination(name, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY)
    end
  });
end)

SILE.registerCommand("pdf:bookmark", function (o,c)
  local dest = SU.required(o, "dest", "pdf:bookmark")
  local title = SU.required(o, "title", "pdf:bookmark")
  local level = o.level or 1
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function ()
      local d = "<</Title("..title..")/A<</S/GoTo/D("..dest..")>>>>"
      pdf.bookmark(d, level)
    end
  });
end)

if SILE.Commands.tocentry then
  SILE.scratch.pdf = { dests = {}, dc = 1 }
  local oldtoc = SILE.Commands.tocentry
  SILE.Commands.tocentry = function (o,c)
    SILE.call("pdf:destination", { name = "dest"..SILE.scratch.pdf.dc } )
    SILE.call("pdf:bookmark", { title = c[1], dest = "dest"..SILE.scratch.pdf.dc, level = o.level })
    oldtoc(o,c)
    SILE.scratch.pdf.dc = SILE.scratch.pdf.dc + 1
  end
end

SILE.registerCommand("pdf:link", function (o,c)
  local dest = SU.required(o, "dest", "pdf:bookmark")
  local llx, lly
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter)
      llx = typesetter.frame.state.cursorX
      lly = SILE.documentState.paperSize[2] - typesetter.frame.state.cursorY
      pdf.begin_annotation()
    end
  });

  local hbox = SILE.Commands["hbox"]({}, c) -- hack
  SILE.typesetter:debugState()
  
  SILE.typesetter:pushHbox({ 
    value = nil, height = 0, width = 0, depth = 0,
    outputYourself= function (self,typesetter) 
      local d = "<</Type/Annot/Subtype/Link/C [ 1 0 0 ]/A<</S/GoTo/D("..dest..")>>>>"
      pdf.end_annotation(d, llx, lly, typesetter.frame.state.cursorX, SILE.documentState.paperSize[2] -typesetter.frame.state.cursorY + hbox.height);
    end
  });end)
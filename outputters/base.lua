local base = pl.class()
base.type = "outputter"
base._name = "base"

function base._init () end

function base.newPage () end

function base.finish () end

function base.getCursor () end

function base.setCursor (_, _, _, _) end

function base.setColor () end

function base.pushColor () end

function base.popColor () end

function base.drawHbox (_, _, _) end

function base.setFont (_, _) end

function base.drawImage (_, _, _, _, _, _) end

function base.getImageSize (_, _) end

function base.drawSVG () end

function base.drawRule (_, _, _, _, _) end

function base.debugFrame (_, _, _) end

function base.debugHbox (_, _, _, _) end

function base.getOutputFilename (_, ext)
  if SILE.outputFilename then return SILE.outputFilename end
  if SILE.masterFilename then return SILE.masterFilename .. "." .. ext end
  SU.error("Cannot guess output filename without an input name")
end

return base

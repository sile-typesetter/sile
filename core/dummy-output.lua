if (not SILE.outputters) then SILE.outputters = {} end

local dummy = function() end

SILE.outputters.dummy = {
  init = dummy,
  newPage = dummy,
  finish = dummy,
  setColor = dummy,
  pushColor = dummy,
  popColor = dummy,
  outputHbox = dummy,
  setFont = dummy,
  drawImage = dummy,
  imageSize = dummy,
  moveTo = dummy,
  rule = dummy,
  debugFrame = dummy,
  debugHbox = dummy
}

SILE.outputter = SILE.outputters.dummy

if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local dummy = function() end

SILE.outputters.dummy = {

  init = dummy,

  newPage = dummy,

  finish = dummy,

  cursor = function()
    return cursorX, cursorY
  end,

  moveTo = dummy,

  setColor = dummy,

  pushColor = dummy,

  popColor = dummy,

  outputHbox = dummy,

  setFont = dummy,

  drawImage = dummy,

  imageSize = dummy,

  drawSVG = dummy,

  rule = dummy,

  debugFrame = dummy,

  debugHbox = dummy

}

SILE.outputter = SILE.outputters.dummy

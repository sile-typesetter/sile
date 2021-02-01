if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local dummy = function() end

SILE.outputters.dummy = {

  init = dummy,

  newPage = dummy,

  finish = dummy,

  getCursor = function (_)
    return cursorX, cursorY
  end,

  moveTo = dummy,

  setCursor = dummy,

  setColor = dummy,

  pushColor = dummy,

  popColor = dummy,

  drawHbox = dummy,

  setFont = dummy,

  drawImage = dummy,

  getImageSize = dummy,

  drawSVG = dummy,

  drawRule = dummy,

  debugFrame = dummy,

  debugHbox = dummy

}

SILE.outputter = SILE.outputters.dummy

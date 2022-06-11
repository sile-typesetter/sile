if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local outfile
local started = false

local writeline = function (...)
  local args = table.pack(...)
  for i=1, #args do
    outfile:write(args[i])
  end
end

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

SILE.outputters.text = {

  init = function(self)
    _deprecationCheck(self)
    outfile = io.open(SILE.outputFilename, "w+")
  end,

  newPage = function(self)
    _deprecationCheck(self)
    outfile:write("")
  end,

  finish = function(self)
    _deprecationCheck(self)
    outfile:close()
  end,

  cursor = function (_)
    SU.deprecated("SILE.outputter:cursor", "SILE.outputter:getCursor", "0.10.10", "0.11.0")
  end,

  getCursor = function (self)
    _deprecationCheck(self)
    return cursorX, cursorY
  end,

  moveTo = function (_, _, _)
    SU.deprecated("SILE.outputter:moveTo", "SILE.outputter:setCursor", "0.10.10", "0.11.0")
  end,

  setCursor = function (self, x, y, relative)
    _deprecationCheck(self)
    local bs = SILE.measurement("0.8bs"):tonumber()
    local spc = SILE.measurement("0.8spc"):tonumber()
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    local newx, newy = offset.x + x, offset.y - y
    if started then
      if newx < cursorX then
          outfile:write("\n")
      elseif newy > cursorY then
        if newy - cursorY > bs then
          outfile:write("\n")
        else
          outfile:write("‫")
        end
      elseif newx > cursorX then
        if newx - cursorX > spc then
          outfile:write(" ")
        else
          outfile:write("‫")
        end
      end
    end
    cursorY = newy
    cursorX = newx
  end,

  setColor = function(self)
    _deprecationCheck(self)
  end,

  pushColor = function (self)
    _deprecationCheck(self)
  end,

  popColor = function (self)
    _deprecationCheck(self)
  end,

  outputHbox = function (_, _, _)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
  end,

  drawHbox = function (self, value, width)
    _deprecationCheck(self)
    width = SU.cast("number", width)
    if not value.text then return end
    writeline(value.text)
    if width > 0 then
      started = true
      cursorX = cursorX + width
    end
  end,

  setFont = function (self, _)
    _deprecationCheck(self)
  end,

  drawImage = function (_, _, _, _, _)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
  end,

  imageSize = function (_, _)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
  end,

  getImageSize = function (self, _)
    _deprecationCheck(self)
  end,

  drawSVG = function (self, _, _, _, _)
    _deprecationCheck(self)
  end,

  rule = function (_, _, _, _, _)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
  end,

  drawRule = function (self, _, _, _, _)
    _deprecationCheck(self)
  end,

  debugFrame = function (self, _)
    _deprecationCheck(self)
  end,

  debugHbox = function(self, _, _, _)
    _deprecationCheck(self)
  end

}

SILE.outputter = SILE.outputters.text

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".txt"
end

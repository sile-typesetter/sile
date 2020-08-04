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

  cursor = function()
    _deprecationCheck(self)
    return cursorX, cursorY
  end,

  moveTo = function (self, x, y)
    _deprecationCheck(self)
    local bs = SILE.measurement("0.8bs"):tonumber()
    local spc = SILE.measurement("0.8spc"):tonumber()
    if started then
      if x < cursorX then
          outfile:write("\n")
      elseif y > cursorY then
        if y - cursorY > bs then
          outfile:write("\n")
        else
          outfile:write("‫")
        end
      elseif x > cursorX then
        if x - cursorX > spc then
          outfile:write(" ")
        else
          outfile:write("‫")
        end
      end
    end
    cursorY = y
    cursorX = x
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

  outputHbox = function (self, value, width)
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


  drawImage = function (self, src, _, _, _)
    _deprecationCheck(self)
  end,

  imageSize = function (self, src)
    _deprecationCheck(self)
  end,

  drawSVG = function (self, _, _, _, _)
    _deprecationCheck(self)
  end,

  rule = function (self, _, _, _, _)
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

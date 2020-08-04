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

SILE.outputters.text = {

  init = function(self)
    outfile = io.open(SILE.outputFilename, "w+")
  end,

  newPage = function(self)
    outfile:write("")
  end,

  finish = function(self)
    outfile:close()
  end,

  cursor = function()
    return cursorX, cursorY
  end,

  moveTo = function (self, x, y)
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
  end,

  pushColor = function () end,

  popColor = function () end,

  outputHbox = function (_, value, width)
    width = SU.cast("number", width)
    if not value.text then return end
    writeline(value.text)
    if width > 0 then
      started = true
      cursorX = cursorX + width
    end
  end,

  setFont = function (_, _) end,

  drawImage = function (_, _, _, _, _) end,

  imageSize = function (_, _) end,

  drawSVG = function (_, _, _, _, _) end,

  rule = function (_, _, _, _, _) end,

  debugFrame = function (_, _) end,

  debugHbox = function(_, _, _, _) end

}

SILE.outputter = SILE.outputters.text

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".txt"
end

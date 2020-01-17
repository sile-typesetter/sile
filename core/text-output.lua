if (not SILE.outputters) then SILE.outputters = {} end

local outfile
local cursorX = 0
local cursorY = 0
local started = false

local writeline = function (...)
  local args = table.pack(...)
  for i=1, #args do
    outfile:write(args[i])
  end
end

SILE.outputters.text = {
  init = function()
    outfile = io.open(SILE.outputFilename, "w+")
  end,
  newPage = function()
    outfile:write("")
  end,
  finish = function()
    outfile:close()
  end,
  setColor = function() end,
  pushColor = function () end,
  popColor = function () end,
  outputHbox = function (value, width)
    width = SU.cast("number", width)
    if not value.text then return end
    writeline(value.text)
    if width > 0 then
      started = true
      cursorX = cursorX + width
    end
  end,
  setFont = function () end,
  drawImage = function () end,
  imageSize = function () end,
  moveTo = function (x, y)
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
  rule = function () end,
  debugFrame = function (_) end,
  debugHbox = function() end
}

SILE.outputter = SILE.outputters.text

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".txt"
end

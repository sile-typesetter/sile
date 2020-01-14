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
    if width > 0 then
      writeline(value.text)
      started = true
      cursorX = cursorX + width
    end
  end,
  setFont = function () end,
  drawImage = function () end,
  imageSize = function () end,
  moveTo = function (x, y)
    if started then
      if y > cursorY or x < cursorX then
        outfile:write("\n")
      elseif x > cursorX then
        outfile:write(" ")
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

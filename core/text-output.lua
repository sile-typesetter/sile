if (not SILE.outputters) then SILE.outputters = {} end

local outfile
local cursorX = 0
local cursorY = 0
local hboxCount = 0

local writeline = function (...)
  local args = table.pack(...)
  if hboxCount >= 1 then outfile:write(" ") end
  for i=1, #args do
    outfile:write(args[i])
    if i < #args then outfile:write(" ") end
    hboxCount = hboxCount + 1
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
  outputHbox = function (value)
    writeline(value.text)
  end,
  setFont = function () end,
  drawImage = function () end,
  imageSize = function () end,
  moveTo = function (x, y)
    if y > cursorY or x <= cursorX then
      outfile:write("\n")
      hboxCount = 0
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

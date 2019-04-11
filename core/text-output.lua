if (not SILE.outputters) then SILE.outputters = {} end

local outfile
local writeline = function (...)
  local args = table.pack(...)
  for i=1, #args do
    outfile:write(args[i])
    if i < #args then outfile:write(" ") end
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
  moveTo = function () end,
  rule = function () end,
  debugFrame = function (self) end,
  debugHbox = function() end
}

SILE.outputter = SILE.outputters.text

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".txt"
end

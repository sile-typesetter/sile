if (not SILE.outputters) then SILE.outputters = {} end

local lastFont
local outfile
local writeline = function (...)
	local args = table.pack(...)
	for i=1, #args do
		outfile:write(args[i])
		if i < #args then outfile:write("\t") end
	end
	outfile:write("\n")
end
local cx
local cy

SILE.outputters.debug = {
  init = function()
    outfile = io.open(SILE.outputFilename, "w+")
    writeline("Set paper size ", SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    writeline("Begin page")
  end,
  newPage = function()
    writeline("New page")
  end,
  finish = function()
    writeline("End page")
    writeline("Finish")
    outfile:close()
  end,
  setColor = function(self, color)
    writeline("Set color", color.r, color.g, color.b)
  end,
  pushColor = function (self, color)
    writeline("Push color", ("%.4g"):format(color.r), ("%.4g"):format(color.g), ("%.4g"):format(color.b))
  end,
  popColor = function (self)
    writeline("Pop color")
  end,
  outputHbox = function (value, width)
    buf = {}
    for i=1, #(value.glyphString) do
      buf[#buf+1] = value.glyphString[i]
    end
    buf = table.concat(buf, " ")
    writeline("T", buf, "("..value.text..")")
  end,
  setFont = function (options)
    local font = SILE.font._key(options)
    if lastFont ~= font then
      writeline("Set font ", SILE.font._key(options))
      lastFont = font
    end
  end,
  drawImage = function (src, x, y, width, height)
    writeline("Draw image", src, string.format("%.4f %.4f %.4f %.4f" , x, y, width, height))
  end,
  imageSize = function (src)
    local pdf = require("justenoughlibtexpdf")
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,
  moveTo = function (x, y)
    if string.format("%.4f", x) ~= string.format("%.4f", cx) then writeline("Mx ", string.format("%.4f", x)); cx = x end
    if string.format("%.4f", y) ~= string.format("%.4f", cy) then writeline("My ", string.format("%.4f", y)); cy = y end
  end,
  rule = function (x, y, width, depth)
    writeline("Draw line", string.format("%.4f %.4f %.4f %.4f", x, y, width, depth))
  end,
  debugFrame = function (self, frame)
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
  end
}

SILE.outputter = SILE.outputters.debug

if not SILE.outputFilename then
  SILE.outputFilename = SILE.masterFilename..".debug"
end

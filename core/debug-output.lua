if (not SILE.outputters) then SILE.outputters = {} end
local f
local cx
local cy
SILE.outputters.debug = {
  init = function()
    print("Set paper size ", SILE.documentState.paperSize[1],SILE.documentState.paperSize[2])
    print("Begin page")
  end,
  newPage = function()
    print("New page")
  end,
  finish = function()
    print("End page")
    print("Finish")
  end,
  setColor = function(self, color)
    print("Set color", color.r, color.g, color.b)
  end,
  pushColor = function (self, color)
    print("Push color", ("%.4g"):format(color.r), ("%.4g"):format(color.g),("%.4g"):format(color.b))
  end,
  popColor = function (self)
    print("Pop color")
  end,
  outputHbox = function (value,w)
    buf = {}
    for i=1,#(value.glyphString) do
      buf[#buf+1] = value.glyphString[i]
    end
    buf = table.concat(buf, " ")
    print("T", buf, "("..value.text..")")
  end,
  setFont = function (options)
    if f ~= SILE.font._key(options) then
      print("Set font ", SILE.font._key(options))
      f = SILE.font._key(options)
    end
  end,
  drawImage = function (src, x,y,w,h)
    print("Draw image", src, string.format("%.4f %.4f %.4f %.4f",x, y, w, h))
  end,
  imageSize = function (src)
    local pdf = require("justenoughlibtexpdf")
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,
  moveTo = function (x,y)
    if string.format("%.4f",x) ~= string.format("%.4f",cx) then print("Mx ",string.format("%.4f",x)); cx = x end
    if string.format("%.4f",y) ~= string.format("%.4f",cy) then print("My ",string.format("%.4f",y)); cy = y end
  end,
  rule = function (x,y,w,d)
    print("Draw line", string.format("%.4f %.4f %.4f %.4f",x, y, w, d))
  end,
  debugFrame = function (self,f)
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
  end
}

SILE.outputter = SILE.outputters.debug

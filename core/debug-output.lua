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
    print("Push color", ("%.5g"):format(color.r), ("%.5g"):format(color.g),("%.5g"):format(color.b))
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
    print("Draw image", src, string.format("%.5f %.5f %.5f %.5f",x, y, w, h))
  end,
  imageSize = function (src)
    local pdf = require("justenoughlibtexpdf");
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,
  moveTo = function (x,y)
    if x ~= cx then print("Mx ",string.format("%.5f",x)); cx = x end
    if y ~= cy then print("My ",string.format("%.5f",y)); cy = y end
  end,
  rule = function (x,y,w,d)
    print("Draw line", x, y, w, d)
  end,
  debugFrame = function (self,f)
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
  end
}

SILE.outputter = SILE.outputters.debug

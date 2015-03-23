if (not SILE.outputters) then SILE.outputters = {} end
SILE.outputters.debug = {
  init = function()
    print("Open file", SILE.outputFilename)
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
    print("Push color", color.r, color.g, color.b)
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
    print("Output glyph string", buf, "("..value.text..")")
  end,
  setFont = function (options)
    print("Set font ", SILE.font._key(options))
  end,
  drawImage = function (src, x,y,w,h)
    print("Draw image", src, x, y, w, h)
  end,
  imageSize = function (src)
    local pdf = require("justenoughlibtexpdf");
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,
  moveTo = function (x,y)
    print("Move to", x, y)
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

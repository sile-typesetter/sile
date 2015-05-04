local pdf = require("justenoughlibtexpdf");
if (not SILE.outputters) then SILE.outputters = {} end
local cursorX = 0
local cursorY = 0
local font = 0
local lastW = 0
SILE.outputters.libtexpdf = {
  init = function()
    pdf.init(SILE.outputFilename, SILE.documentState.paperSize[1],SILE.documentState.paperSize[2])
    pdf.beginpage()
  end,
  newPage = function()
    pdf.endpage()
    pdf.beginpage()
  end,
  finish = function()
    pdf.endpage()
    pdf.finish()
  end,
  setColor = function(self, color)
    pdf.setcolor(color.r, color.g, color.b)
  end,
  pushColor = function (self, color)
    pdf.colorpush(color.r, color.g, color.b)
  end,
  popColor = function (self)
    pdf.colorpop()
  end,
  outputHbox = function (value,w)
    if not value.glyphString then return end
    local buf = {}
    for i=1,#(value.glyphString) do
      glyph = value.glyphString[i]
      buf[#buf+1] = string.char(math.floor(glyph % 2^32 / 2^8))
      buf[#buf+1] = string.char(glyph % 0x100)
    end
    buf = table.concat(buf, "")
    pdf.setstring(cursorX, cursorY, buf, string.len(buf), font, w)
    lastW = w
  end,
  setFont = function (options)
    if SILE.font._key(options) == lastkey then return end
    lastkey = SILE.font._key(options)
    font = SILE.font.cache(options, SILE.shaper.getFace)
    f = pdf.loadfont(font)
    if f< 0 then SU.error("Font loading error for "..options) end
    font = f
  end,
  drawImage = function (src, x,y,w,h)
    pdf.drawimage(src, x, y, w, h)
  end,
  imageSize = function (src)
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,
  moveTo = function (x,y)
    cursorX = x
    cursorY = SILE.documentState.paperSize[2] - y
  end,
  rule = function (x,y,w,d)
    pdf.setrule(x,SILE.documentState.paperSize[2] -y,w,d)
  end,
  debugFrame = function (self,f)
    pdf.colorpush(0.8,0,0)
    self.rule(f:left(), f:top(), f:width(), 0.5)
    self.rule(f:left(), f:top(), 0.5, - f:height())
    self.rule(f:right(), f:top(), 0.5, - f:height())
    self.rule(f:left(), f:bottom(), f:width(), 0.5)
    --self.rule(f:left() + f:width()/2 - 5, (f:top() + f:bottom())/2+5, 10, 10)
    local stuff = SILE.shaper:shape(f.id)
    stuff = stuff[1].nodes[1].value.glyphString -- Horrible hack
    local buf = {}
    for i=1,#stuff do
      glyph = stuff[i]
      buf[#buf+1] = string.char(math.floor(glyph % 2^32 / 2^8))
      buf[#buf+1] = string.char(glyph % 0x100)
    end
    buf = table.concat(buf, "")
    if font == 0 then SILE.outputter.setFont({}) end
    pdf.setstring(f:left(), SILE.documentState.paperSize[2] -f:top(), buf, string.len(buf), font, 0)
    pdf.colorpop()
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
  end
}

SILE.outputter = SILE.outputters.libtexpdf

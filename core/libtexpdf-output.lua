local pdf = require("justenoughlibtexpdf")
if (not SILE.outputters) then SILE.outputters = {} end
local cursorX = 0
local cursorY = 0
local font = 0
local started = false
local lastkey

local function ensureInit ()
  if not started then
    pdf.init(SILE.outputFilename, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    pdf.beginpage()
    started = true
  end
end

SILE.outputters.libtexpdf = {

  init = function ()
    -- We don't do anything yet because this commits us to a page size.
  end,

  _init = ensureInit,

  newPage = function ()
    ensureInit()
    pdf.endpage()
    pdf.beginpage()
  end,

  finish = function ()
    if not started then return end
    pdf.endpage()
    pdf.finish()
    started = false
    lastkey = nil
  end,

  setColor = function (_, color)
    ensureInit()
    if color.r then pdf.setcolor_rgb(color.r, color.g, color.b) end
    if color.c then pdf.setcolor_cmyk(color.c, color.m, color.y, color.k) end
    if color.l then pdf.setcolor_gray(color.l) end
  end,

  pushColor = function (_, color)
    ensureInit()
    if color.r then pdf.colorpush_rgb(color.r, color.g, color.b) end
    if color.c then pdf.colorpush_cmyk(color.c, color.m, color.y, color.k) end
    if color.l then pdf.colorpush_gray(color.l) end
  end,

  popColor = function (_)
    ensureInit()
    pdf.colorpop()
  end,

  cursor = function (_)
    return cursorX, cursorY
  end,

  outputHbox = function (value, width)
    width = SU.cast("number", width)
    ensureInit()
    if not value.glyphString then return end
    -- Nodes which require kerning or have offsets to the glyph
    -- position should be output a glyph at a time. We pass the
    -- glyph advance from the htmx table, so that libtexpdf knows
    -- how wide each glyph is. It uses this to then compute the
    -- relative position between the pen after the glyph has been
    -- painted (cursorX + glyphAdvance) and the next painting
    -- position (cursorX + width - remember that the box's "width"
    -- is actually the shaped x_advance).
    if value.complex then
      for i = 1, #(value.items) do
        local glyph = value.items[i].gid
        local buf = string.char(math.floor(glyph % 2^32 / 2^8)) .. string.char(glyph % 0x100)
        pdf.setstring(cursorX + (value.items[i].x_offset or 0), cursorY + (value.items[i].y_offset or 0), buf, string.len(buf), font, value.items[i].glyphAdvance)
        cursorX = cursorX + value.items[i].width
      end
      return
    end
    local buf = {}
    for i = 1, #(value.glyphString) do
      local glyph = value.glyphString[i]
      buf[#buf+1] = string.char(math.floor(glyph % 2^32 / 2^8))
      buf[#buf+1] = string.char(glyph % 0x100)
    end
    buf = table.concat(buf, "")
    pdf.setstring(cursorX, cursorY, buf, string.len(buf), font, width)
  end,

  setFont = function (options)
    ensureInit()
    if SILE.font._key(options) == lastkey then return end
    lastkey = SILE.font._key(options)
    font = SILE.font.cache(options, SILE.shaper.getFace)
    if options.direction == "TTB" then
      font.layout_dir = 1
    end
    if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
      pdf.setdirmode(1)
    else
      pdf.setdirmode(0)
    end
    local pdffont = pdf.loadfont(font)
    if pdffont < 0 then SU.error("Font loading error for "..options) end
    font = pdffont
  end,

  drawImage = function (src, x, y, width, height)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    ensureInit()
    pdf.drawimage(src, x, y, width, height)
  end,

  imageSize = function (src)
    ensureInit() -- in case it's a PDF file
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,

  moveTo = function (x, y)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    cursorX = x
    cursorY = SILE.documentState.paperSize[2] - y
  end,

  rule = function (x, y, width, depth)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    depth = SU.cast("number", depth)
    ensureInit()
    pdf.setrule(x, SILE.documentState.paperSize[2] - y - depth, width, depth)
  end,

  debugFrame = function (self, frame)
    ensureInit()
    pdf.colorpush_rgb(0.8, 0, 0)
    self.rule(frame:left(), frame:top(), frame:width(), 0.5)
    self.rule(frame:left(), frame:top(), 0.5, frame:height())
    self.rule(frame:right(), frame:top(), 0.5, frame:height())
    self.rule(frame:left(), frame:bottom(), frame:width(), 0.5)
    --self.rule(frame:left() + frame:width()/2 - 5, (frame:top() + frame:bottom())/2+5, 10, 10)
    local stuff = SILE.shaper:createNnodes(frame.id, SILE.font.loadDefaults({}))
    stuff = stuff[1].nodes[1].value.glyphString -- Horrible hack
    local buf = {}
    for i = 1, #stuff do
      local glyph = stuff[i]
      buf[#buf+1] = string.char(math.floor(glyph % 2^32 / 2^8))
      buf[#buf+1] = string.char(glyph % 0x100)
    end
    buf = table.concat(buf, "")
    if font == 0 then SILE.outputter.setFont(SILE.font.loadDefaults({})) end
    pdf.setstring(frame:left():tonumber(), (SILE.documentState.paperSize[2] - frame:top()):tonumber(), buf, string.len(buf), font, 0)
    pdf.colorpop()
  end,

  debugHbox = function (hbox, scaledWidth)
    ensureInit()
    pdf.colorpush_rgb(0.8, 0.3, 0.3)
    pdf.setrule(cursorX, cursorY+(hbox.height), scaledWidth+0.5, 0.5)
    pdf.setrule(cursorX, cursorY, 0.5, hbox.height)
    pdf.setrule(cursorX, cursorY, scaledWidth+0.5, 0.5)
    pdf.setrule(cursorX+scaledWidth, cursorY, 0.5, hbox.height)
    if hbox.depth then
      pdf.setrule(cursorX, cursorY-(hbox.depth), scaledWidth, 0.5)
      pdf.setrule(cursorX+scaledWidth, cursorY-(hbox.depth), 0.5, hbox.depth)
      pdf.setrule(cursorX, cursorY-(hbox.depth), 0.5, hbox.depth)

    end
    pdf.colorpop()
  end

}

SILE.outputter = SILE.outputters.libtexpdf

if not SILE.outputFilename and SILE.masterFilename then
	SILE.outputFilename = SILE.masterFilename..".pdf"
end

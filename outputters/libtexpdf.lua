local base = require("outputters.base")
local pdf = require("justenoughlibtexpdf")

local cursorX = 0
local cursorY = 0

local started = false
local lastkey = false

local debugfont = SILE.font.loadDefaults({ family = "Gentium Plus", language = "en", size = 10 })

local glyph2string = function (glyph)
  return string.char(math.floor(glyph % 2^32 / 2^8)) .. string.char(glyph % 0x100)
end

local _dl = 0.5

local _debugfont
local _font

local libtexpdf = pl.class(base)
libtexpdf._name = "libtexpdf"

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function libtexpdf:_init () end

function libtexpdf:_ensureInit ()
  if not started then
    local w, h = SILE.documentState.paperSize[1], SILE.documentState.paperSize[2]
    pdf.init(self:getOutputFilename("pdf"), w, h, SILE.full_version)
    pdf.beginpage()
    started = true
  end
end

function libtexpdf:newPage ()
  self:_ensureInit()
  pdf.endpage()
  pdf.beginpage()
end

function libtexpdf:finish ()
  self:_ensureInit()
  pdf.endpage()
  pdf.finish()
  started = false
  lastkey = nil
end

function libtexpdf.getCursor (_)
  return cursorX, cursorY
end

function libtexpdf.setCursor (_, x, y, relative)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  cursorX = offset.x + x
  cursorY = offset.y + (relative and 0 or SILE.documentState.paperSize[2]) - y
end

function libtexpdf:setColor (color)
  self:_ensureInit()
  if color.r then pdf.setcolor_rgb(color.r, color.g, color.b) end
  if color.c then pdf.setcolor_cmyk(color.c, color.m, color.y, color.k) end
  if color.l then pdf.setcolor_gray(color.l) end
end

function libtexpdf:pushColor (color)
  self:_ensureInit()
  if color.r then pdf.colorpush_rgb(color.r, color.g, color.b) end
  if color.c then pdf.colorpush_cmyk(color.c, color.m, color.y, color.k) end
  if color.l then pdf.colorpush_gray(color.l) end
end

function libtexpdf:popColor ()
  self:_ensureInit()
  pdf.colorpop()
end

function libtexpdf:_drawString (str, width, x_offset, y_offset)
  local x, y = self:getCursor()
  pdf.colorpush_rgb(0,0,0)
  pdf.colorpop()
  pdf.setstring(x+x_offset, y+y_offset, str, string.len(str), _font, width)
end

function libtexpdf:drawHbox (value, width)
  width = SU.cast("number", width)
  self:_ensureInit()
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
    for i = 1, #value.items do
      local item = value.items[i]
      local buf = glyph2string(item.gid)
      self:_drawString(buf, item.glyphAdvance, item.x_offset or 0, item.y_offset or 0)
      self:setCursor(item.width, 0, true)
    end
  else
    local buf = {}
    for i = 1, #value.glyphString do
      buf[i] = glyph2string(value.glyphString[i])
    end
    buf = table.concat(buf, "")
    self:_drawString(buf, width, 0, 0)
  end
end

function libtexpdf:_withDebugFont (callback)
  if not _debugfont then
    _debugfont = self:setFont(debugfont)
  end
  local oldfont = _font
  _font = _debugfont
  callback()
  _font = oldfont
end

function libtexpdf:setFont (options)
  self:_ensureInit()
  local key = SILE.font._key(options)
  if lastkey and key == lastkey then return _font end
  local font = SILE.font.cache(options, SILE.shaper.getFace)
  if options.direction == "TTB" then
    font.layout_dir = 1
  end
  if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
    pdf.setdirmode(1)
  else
    pdf.setdirmode(0)
  end
  _font = pdf.loadfont(font)
  if _font < 0 then SU.error("Font loading error for "..options) end
  lastkey = key
  return _font
end

function libtexpdf:drawImage (src, x, y, width, height)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_ensureInit()
  pdf.drawimage(src, x, y, width, height)
end

function libtexpdf:getImageSize (src)
  self:_ensureInit() -- in case it's a PDF file
  local llx, lly, urx, ury = pdf.imagebbox(src)
  return (urx-llx), (ury-lly)
end

function libtexpdf:drawSVG (figure, x, y, _, height, scalefactor)
  self:_ensureInit()
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  height = SU.cast("number", height)
  pdf.add_content("q")
  self:setCursor(x, y)
  x, y = self:getCursor()
  local newy = y - SILE.documentState.paperSize[2] + height
  pdf.add_content(table.concat({ scalefactor, 0, 0, -scalefactor, x, newy, "cm" }, " "))
  pdf.add_content(figure)
  pdf.add_content("Q")
end

function libtexpdf:drawRule (x, y, width, height)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_ensureInit()
  local paperY = SILE.documentState.paperSize[2]
  pdf.setrule(x, paperY - y - height, width, height)
end

function libtexpdf:debugFrame (frame)
  self:_ensureInit()
  self:pushColor({ r = 0.8, g = 0, b = 0 })
  self:drawRule(frame:left()-_dl/2, frame:top()-_dl/2, frame:width()+_dl, _dl)
  self:drawRule(frame:left()-_dl/2, frame:top()-_dl/2, _dl, frame:height()+_dl)
  self:drawRule(frame:right()-_dl/2, frame:top()-_dl/2, _dl, frame:height()+_dl)
  self:drawRule(frame:left()-_dl/2, frame:bottom()-_dl/2, frame:width()+_dl, _dl)
  -- self:drawRule(frame:left() + frame:width()/2 - 5, (frame:top() + frame:bottom())/2+5, 10, 10)
  local stuff = SILE.shaper:createNnodes(frame.id, debugfont)
  stuff = stuff[1].nodes[1].value.glyphString -- Horrible hack
  local buf = {}
  for i = 1, #stuff do
    buf[i] = glyph2string(stuff[i])
  end
  buf = table.concat(buf, "")
  self:_withDebugFont(function ()
    self:setCursor(frame:left():tonumber() - _dl/2, frame:top():tonumber() + _dl/2)
    self:_drawString(buf, 0, 0, 0)
  end)
  self:popColor()
end

function libtexpdf:debugHbox (hbox, scaledWidth)
  self:_ensureInit()
  self:pushColor({ r = 0.8, g = 0.3, b = 0.3 })
  local paperY = SILE.documentState.paperSize[2]
  local x, y = self:getCursor()
  y = paperY - y
  self:drawRule(x-_dl/2, y-_dl/2-hbox.height, scaledWidth+_dl, _dl)
  self:drawRule(x-_dl/2, y-hbox.height-_dl/2, _dl, hbox.height+hbox.depth+_dl)
  self:drawRule(x-_dl/2, y-_dl/2, scaledWidth+_dl, _dl)
  self:drawRule(x+scaledWidth-_dl/2, y-hbox.height-_dl/2, _dl, hbox.height+hbox.depth+_dl)
  if hbox.depth > SILE.length(0) then
    self:drawRule(x-_dl/2, y+hbox.depth-_dl/2, scaledWidth+_dl, _dl)
  end
  self:popColor()
end

return libtexpdf

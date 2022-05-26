local pdf = require("justenoughlibtexpdf")

if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local started = false
local lastkey = false

local debugfont = SILE.font.loadDefaults({ family = "Gentium Plus", language = "en", size = 10 })

local function ensureInit ()
  if not started then
    pdf.init(SILE.outputFilename, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2], SILE.full_version)
    pdf.beginpage()
    started = true
  end
end

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

local glyph2string = function (glyph)
  return string.char(math.floor(glyph % 2^32 / 2^8)) .. string.char(glyph % 0x100)
end

local _dl = 0.5

SILE.outputters.libtexpdf = {

  init = function (self)
    _deprecationCheck(self)
    -- We don't do anything yet because this commits us to a page size.
  end,

  _init = ensureInit,

  newPage = function (self)
    _deprecationCheck(self)
    ensureInit()
    pdf.endpage()
    pdf.beginpage()
  end,

  finish = function (self)
    _deprecationCheck(self)
    ensureInit()
    pdf.endpage()
    pdf.finish()
    started = false
    lastkey = nil
  end,

  cursor = function (self)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:cursor", "SILE.outputter:getCursor", "0.10.10", "0.11.0")
    return self:getCursor()
  end,

  getCursor = function (self)
    _deprecationCheck(self)
    return cursorX, cursorY
  end,

  moveTo = function (self, x, y)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:moveTo", "SILE.outputter:setCursor", "0.10.10", "0.11.0")
    return self:setCursor(x, y)
  end,

  setCursor = function (self, x, y, relative)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    cursorX = offset.x + x
    cursorY = offset.y + (relative and 0 or SILE.documentState.paperSize[2]) - y
  end,

  setColor = function (self, color)
    _deprecationCheck(self)
    ensureInit()
    if color.r then pdf.setcolor_rgb(color.r, color.g, color.b) end
    if color.c then pdf.setcolor_cmyk(color.c, color.m, color.y, color.k) end
    if color.l then pdf.setcolor_gray(color.l) end
  end,

  pushColor = function (self, color)
    _deprecationCheck(self)
    ensureInit()
    if color.r then pdf.colorpush_rgb(color.r, color.g, color.b) end
    if color.c then pdf.colorpush_cmyk(color.c, color.m, color.y, color.k) end
    if color.l then pdf.colorpush_gray(color.l) end
  end,

  popColor = function (self)
    _deprecationCheck(self)
    ensureInit()
    pdf.colorpop()
  end,

  outputHbox = function (self, value, width)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
    return self:drawHbox(value, width)
  end,

  _drawString = function(self, str, width, x_offset, y_offset)
    local x, y = self:getCursor()
    pdf.colorpush_rgb(0,0,0)
    pdf.colorpop()
    pdf.setstring(x+x_offset, y+y_offset, str, string.len(str), self._font, width)
  end,

  drawHbox = function (self, value, width)
    _deprecationCheck(self)
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
  end,

  _debugfont = nil,

  _withDebugFont = function (self, callback)
    if not self._debugfont then
      self._debugfont = self:setFont(debugfont)
    end
    local oldfont = self._font
    self._font = self._debugfont
    callback()
    self._font = oldfont
  end,

  _font = nil,

  setFont = function (self, options)
    _deprecationCheck(self)
    ensureInit()
    local key = SILE.font._key(options)
    if lastkey and key == lastkey then return self._font end
    local font = SILE.font.cache(options, SILE.shaper.getFace)
    if options.direction == "TTB" then
      font.layout_dir = 1
    end
    if SILE.typesetter.frame and SILE.typesetter.frame:writingDirection() == "TTB" then
      pdf.setdirmode(1)
    else
      pdf.setdirmode(0)
    end
    self._font = pdf.loadfont(font)
    if self._font < 0 then SU.error("Font loading error for "..options) end
    lastkey = key
    return self._font
  end,

  drawImage = function (self, src, x, y, width, height)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    ensureInit()
    pdf.drawimage(src, x, y, width, height)
  end,

  imageSize = function (self, src)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
    return self:getImageSize(src)
  end,

  getImageSize = function (self, src)
    _deprecationCheck(self)
    ensureInit() -- in case it's a PDF file
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,

  drawSVG = function (self, figure, x, y, _, height, scalefactor)
    _deprecationCheck(self)
    ensureInit()
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
  end,

  rule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
    return self:drawRule(x, y, width, depth)
  end,

  drawRule = function (self, x, y, width, height)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    ensureInit()
    local paperY = SILE.documentState.paperSize[2]
    pdf.setrule(x, paperY - y - height, width, height)
  end,

  debugFrame = function (self, frame)
    _deprecationCheck(self)
    ensureInit()
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
  end,

  debugHbox = function (self, hbox, scaledWidth)
    _deprecationCheck(self)
    ensureInit()
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

}

SILE.outputter = SILE.outputters.libtexpdf

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".pdf"
end

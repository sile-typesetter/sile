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

local outputter = pl.class(base)
outputter._name = "libtexpdf"
outputter.extension = "pdf"

-- N.B. Sometimes setCoord is called before the outputter has ensured initialization.
-- This ok for coordinates manipulation, at these points we know the page size.
local deltaX
local deltaY
local function trueXCoord (x)
  if not deltaX then
    deltaX = (SILE.documentState.sheetSize[1] - SILE.documentState.paperSize[1]) / 2
  end
  return x + deltaX
end
local function trueYCoord (y)
  if not deltaY then
    deltaY = (SILE.documentState.sheetSize[2] - SILE.documentState.paperSize[2]) / 2
  end
  return y + deltaY
end

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function outputter:_init () end

function outputter:_ensureInit ()
  if not started then
    local w, h = SILE.documentState.sheetSize[1], SILE.documentState.sheetSize[2]
    local fname = self:getOutputFilename()
    -- Ideally we could want to set the PDF CropBox, BleedBox, TrimBox...
    -- Our wrapper only manages the MediaBox at this point.
    pdf.init(fname == "-" and "/dev/stdout" or fname, w, h, SILE.full_version)
    pdf.beginpage()
    started = true
  end
end

function outputter:newPage ()
  self:_ensureInit()
  pdf.endpage()
  pdf.beginpage()
end

-- pdf stucture package needs a tie in here
function outputter._endHook (_)
end

function outputter:finish ()
  self:_ensureInit()
  pdf.endpage()
  self:_endHook()
  pdf.finish()
  started = false
  lastkey = nil
end

function outputter.getCursor (_)
  return cursorX, cursorY
end

function outputter.setCursor (_, x, y, relative)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  cursorX = offset.x + x
  cursorY = offset.y + (relative and 0 or SILE.documentState.paperSize[2]) - y
end

function outputter:setColor (color)
  self:_ensureInit()
  if color.r then pdf.setcolor_rgb(color.r, color.g, color.b) end
  if color.c then pdf.setcolor_cmyk(color.c, color.m, color.y, color.k) end
  if color.l then pdf.setcolor_gray(color.l) end
end

function outputter:pushColor (color)
  self:_ensureInit()
  if color.r then pdf.colorpush_rgb(color.r, color.g, color.b) end
  if color.c then pdf.colorpush_cmyk(color.c, color.m, color.y, color.k) end
  if color.l then pdf.colorpush_gray(color.l) end
end

function outputter:popColor ()
  self:_ensureInit()
  pdf.colorpop()
end

function outputter:_drawString (str, width, x_offset, y_offset)
  local x, y = self:getCursor()
  pdf.colorpush_rgb(0,0,0)
  pdf.colorpop()
  pdf.setstring(trueXCoord(x+x_offset), trueYCoord(y+y_offset), str, string.len(str), _font, width)
end

function outputter:drawHbox (value, width)
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

function outputter:_withDebugFont (callback)
  if not _debugfont then
    _debugfont = self:setFont(debugfont)
  end
  local oldfont = _font
  _font = _debugfont
  callback()
  _font = oldfont
end

function outputter:setFont (options)
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
  if _font < 0 then SU.error("Font loading error for " .. pl.pretty.write(options, "")) end
  lastkey = key
  return _font
end

function outputter:drawImage (src, x, y, width, height, pageno)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_ensureInit()
  pdf.drawimage(src, trueXCoord(x), trueYCoord(y), width, height, pageno or 1)
end

function outputter:getImageSize (src, pageno)
  self:_ensureInit() -- in case it's a PDF file
  local llx, lly, urx, ury, xresol, yresol = pdf.imagebbox(src, pageno or 1)
  return (urx-llx), (ury-lly), xresol, yresol
end

function outputter:drawSVG (figure, x, y, _, height, scalefactor)
  self:_ensureInit()
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  height = SU.cast("number", height)
  pdf.add_content("q")
  self:setCursor(x, y)
  x, y = self:getCursor()
  local newy = y - SILE.documentState.paperSize[2] / 2 + height - SILE.documentState.sheetSize[2] / 2
  pdf.add_content(table.concat({ scalefactor, 0, 0, -scalefactor, trueXCoord(x), newy, "cm" }, " "))
  pdf.add_content(figure)
  pdf.add_content("Q")
end

function outputter:drawRule (x, y, width, height)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_ensureInit()
  local paperY = SILE.documentState.paperSize[2]
  pdf.setrule(trueXCoord(x), trueYCoord(paperY - y - height), width, height)
end

function outputter:debugFrame (frame)
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

function outputter:debugHbox (hbox, scaledWidth)
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

-- The methods below are only implemented on outputters supporting these features.
-- In PDF, it relies on transformation matrices, but other backends may call
-- for a different strategy.
-- ! The API is unstable and subject to change. !

function outputter:scaleFn (xorigin, yorigin, xratio, yratio, callback)
  xorigin = SU.cast("number", xorigin)
  yorigin = SU.cast("number", yorigin)
  local x0 = trueXCoord(xorigin)
  local y0 = -trueYCoord(yorigin)
  self:_ensureInit()
  pdf:gsave()
  pdf.setmatrix(1, 0, 0, 1, x0, y0)
  pdf.setmatrix(xratio, 0, 0, yratio, 0, 0)
  pdf.setmatrix(1, 0, 0, 1, -x0, -y0)
  callback()
  pdf:grestore()
end

function outputter:rotateFn (xorigin, yorigin, theta, callback)
  xorigin = SU.cast("number", xorigin)
  yorigin = SU.cast("number", yorigin)
  local x0 = trueXCoord(xorigin)
  local y0 = -trueYCoord(yorigin)
  self:_ensureInit()
  pdf:gsave()
  pdf.setmatrix(1, 0, 0, 1, x0, y0)
  pdf.setmatrix(math.cos(theta), math.sin(theta), -math.sin(theta), math.cos(theta), 0, 0)
  pdf.setmatrix(1, 0, 0, 1, -x0, -y0)
  callback()
  pdf:grestore()
end

-- Other rotation unstable APIs

function outputter:enterFrameRotate (xa, xb, y, theta) -- Unstable API see rotate package
  xa = SU.cast("number", xa)
  xb = SU.cast("number", xb)
  y = SU.cast("number", y)
  -- Keep center point the same?
  local cx0 = trueXCoord(xa)
  local cx1 = trueXCoord(xb)
  local cy = -trueYCoord(y)
  self:_ensureInit()
  pdf:gsave()
  pdf.setmatrix(1, 0, 0, 1, cx1, cy)
  pdf.setmatrix(math.cos(theta), math.sin(theta), -math.sin(theta), math.cos(theta), 0, 0)
  pdf.setmatrix(1, 0, 0, 1, -cx0, -cy)
end

function outputter.leaveFrameRotate (_)
  pdf:grestore()
end

-- Unstable link APIs

function outputter:linkAnchor (x, y, name)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  self:_ensureInit()
  pdf.destination(name, trueXCoord(x), trueYCoord(y))
end

local function borderColor (color)
  if color then
    if color.r then return "/C [" .. color.r .. " " .. color.g .. " " .. color.b .. "]" end
    if color.c then return "/C [" .. color.c .. " " .. color.m .. " " .. color.y .. " " .. color.k .. "]" end
    if color.l then return "/C [" .. color.l .. "]" end
  end
  return ""
end
local function borderStyle (style, width)
  if style == "underline" then return "/BS<</Type/Border/S/U/W " .. width .. ">>" end
  if style == "dashed" then return "/BS<</Type/Border/S/D/D[3 2]/W " .. width .. ">>" end
  return "/Border[0 0 " .. width .. "]"
end

function outputter:enterLinkTarget (_, _) -- destination, options as argument
  -- HACK:
  -- Looking at the code, pdf.begin_annotation does nothing, and Simon wrote a comment
  -- about tracking boxes. Unsure what he implied with this obscure statement.
  -- Sure thing is that some backends may need the destination here, e.g. an HTML backend
  -- would generate a <a href="#destination">, as well as the options possibly for styling
  -- on the link opening?
  self:_ensureInit()
  pdf.begin_annotation()
end
function outputter.leaveLinkTarget (_, x0, y0, x1, y1, dest, opts)
  local bordercolor = borderColor(opts.bordercolor)
  local borderwidth = SU.cast("integer", opts.borderwidth)
  local borderstyle = borderStyle(opts.borderstyle, borderwidth)
  local target = opts.external and "/Type/Action/S/URI/URI" or "/S/GoTo/D"
  local d = "<</Type/Annot/Subtype/Link" .. borderstyle .. bordercolor .. "/A<<" .. target .. "(" .. dest .. ")>>>>"
  pdf.end_annotation(d,
    trueXCoord(x0) , trueYCoord(y0 - opts.borderoffset),
    trueXCoord(x1), trueYCoord(y1 + opts.borderoffset))
end

-- Bookmarks and metadata

local function validate_date (date)
  return string.match(date, [[^D:%d+%s*-%s*%d%d%s*'%s*%d%d%s*'?$]]) ~= nil
end

function outputter:setMetadata (key, value)
  if key == "Trapped" then
    SU.warn("Skipping special metadata key \\Trapped")
    return
  end

  if key == "ModDate" or key == "CreationDate" then
    if not validate_date(value) then
      SU.warn("Invalid date: " .. value)
      return
    end
  else
    -- see comment in on bookmark
    value = SU.utf8_to_utf16be(value)
  end
  self:_ensureInit()
  pdf.metadata(key, value)
end

function outputter:setBookmark (dest, title, level)
  -- Added UTF8 to UTF16-BE conversion
  -- For annotations and bookmarks, text strings must be encoded using
  -- either PDFDocEncoding or UTF16-BE with a leading byte-order marker.
  -- As PDFDocEncoding supports only limited character repertoire for
  -- European languages, we use UTF-16BE for internationalization.
  local ustr = SU.utf8_to_utf16be_hexencoded(title)
  local d = "<</Title<" .. ustr .. ">/A<</S/GoTo/D(" .. dest .. ")>>>>"
  self:_ensureInit()
  pdf.bookmark(d, level)
end

return outputter

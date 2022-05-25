-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local lgi = require("lgi")
local cairo = lgi.cairo
-- local pango = lgi.Pango
-- local fm = lgi.PangoCairo.FontMap.get_default()
-- local pango_context = lgi.Pango.FontMap.create_context(fm)
local imagesize = require("imagesize")

if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local cr
local move -- See https://github.com/pavouk/lgi/issues/48
local sgs

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

SILE.outputters.cairo = {

  init = function (self)
    _deprecationCheck(self)
    local surface = cairo.PdfSurface.create(SILE.outputFilename, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    cr = cairo.Context.create(surface)
    move = cr.move_to
    sgs = cr.show_glyph_string
  end,

  newPage = function (self)
    _deprecationCheck(self)
    cr:show_page()
  end,

  finish = function (self)
    _deprecationCheck(self)
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
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    cursorX = offset.x + x
    cursorY = offset.y - y
    move(cr, cursorX, cursorY)
  end,

  setColor = function (self, color)
    _deprecationCheck(self)
    cr:set_source_rgb(color.r, color.g, color.b)
  end,

  pushColor = function (self)
    _deprecationCheck(self)
  end,

  popColor = function (self)
    _deprecationCheck(self)
  end,

  outputHbox = function (self, value, width)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
    return self:drawHbox(value, width)
  end,

  drawHbox = function (self, value, _)
    _deprecationCheck(self)
    if not value then return end
    if value.pgs then
      sgs(cr, value.font, value.pgs)
    elseif value.text then
      cr:show_text(value.text)
    end
  end,

  setFont = function (self, options)
    _deprecationCheck(self)
    cr:select_font_face(options.font, options.style:lower() == "italic" and 1 or 0, options.weight > 100 and 0 or 1)
    cr:set_font_size(options.size)
  end,

  drawImage = function (self, src, x, y, width, height)
    _deprecationCheck(self)
    local image = cairo.ImageSurface.create_from_png(src)
    if not image then SU.error("Could not load image "..src) end
    local src_width = image:get_width()
    local src_height = image:get_height()
    if not (src_width > 0) then SU.error("Something went wrong loading image "..src) end
    cr:save()
    cr:set_source_surface(image, 0, 0)
    local p = cr:get_source()
    local matrix, sx, sy
    if width or height then
      if width > 0 then sx = src_width / width end
      if height > 0 then sy = src_height / height end
      matrix = cairo.Matrix.create_scale(sx or sy, sy or sx)
    else
      matrix = cairo.Matrix.create_identity()
    end
    matrix:translate(-x, -y)
    p:set_matrix(matrix)
    cr:paint()
    cr:restore()
  end,

  imageSize = function (self, src)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
    return self:getImageSize(src)
  end,

  getImageSize = function (self, src)
    _deprecationCheck(self)
    local box_width, box_height, err = imagesize.imgsize(src)
    if not box_width then
      SU.error(err.." loading image")
    end
    return box_width, box_height
  end,

  drawSVG = function (self)
    _deprecationCheck(self)
  end,

  rule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
    return self:drawRule(x, y, width, depth)
  end,

  drawRule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    cr:rectangle(x, y, width, depth)
    cr:fill()
  end,

  debugFrame = function (self, frame)
    _deprecationCheck(self)
    cr:set_source_rgb(0.8, 0, 0)
    cr:set_line_width(0.5)
    cr:rectangle(frame:left(), frame:top(), frame:width(), frame:height())
    cr:stroke()
    cr:move_to(frame:left() - 10, frame:top() -2)
    cr:show_text(frame.id)
    cr:set_source_rgb(0, 0, 0)
  end,

  debugHbox = function (self, typesetter, hbox, scaledWidth)
    _deprecationCheck(self)
    cr:set_source_rgb(0.9, 0.9, 0.9)
    cr:set_line_width(0.5)
    cr:rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(hbox.height), scaledWidth, hbox.height+hbox.depth)
    if (hbox.depth) then cr:rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(hbox.height), scaledWidth, hbox.height); end
    cr:stroke()
    cr:set_source_rgb(0, 0, 0)
    cr:move_to(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
  end

}

SILE.outputter = SILE.outputters.cairo

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".pdf"
end

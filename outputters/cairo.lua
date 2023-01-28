local base = require("outputters.base")

-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local lgi = require("lgi")
local cairolgi = lgi.cairo
-- local pango = lgi.Pango
-- local fm = lgi.PangoCairo.FontMap.get_default()
-- local pango_context = lgi.Pango.FontMap.create_context(fm)
local imagesize = require("imagesize")

local cursorX = 0
local cursorY = 0

local cr
local move -- See https://github.com/pavouk/lgi/issues/48
local sgs

local outputter = pl.class(base)
outputter._name = "cairo"

function outputter:_init ()
  local fname = self:getOutputFilename("pdf")
  local surface = cairolgi.PdfSurface.create(fname == "-" and "/dev/stdout" or fname, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
  cr = cairolgi.Context.create(surface)
  move = cr.move_to
  sgs = cr.show_glyph_string
end

function outputter.newPage (_)
  cr:show_page()
end

function outputter.getCursor (_)
  return cursorX, cursorY
end

function outputter.setCursor (_, x, y, relative)
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  cursorX = offset.x + x
  cursorY = offset.y - y
  move(cr, cursorX, cursorY)
end

function outputter.setColor (_, color)
  cr:set_source_rgb(color.r, color.g, color.b)
end

function outputter.drawHbox (_, value, _)
  if not value then return end
  if value.pgs then
    sgs(cr, value.font, value.pgs)
  elseif value.text then
    cr:show_text(value.text)
  end
end

function outputter.setFont (_, options)
  cr:select_font_face(options.font, options.style:lower() == "italic" and 1 or 0, options.weight > 100 and 0 or 1)
  cr:set_font_size(options.size)
end

function outputter.drawImage (_, src, x, y, width, height)
  local image = cairolgi.ImageSurface.create_from_png(src)
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
    matrix = cairolgi.Matrix.create_scale(sx or sy, sy or sx)
  else
    matrix = cairolgi.Matrix.create_identity()
  end
  matrix:translate(-x, -y)
  p:set_matrix(matrix)
  cr:paint()
  cr:restore()
end

function outputter.getImageSize (_, src)
  local box_width, box_height, err = imagesize.imgsize(src)
  if not box_width then
    SU.error(err.." loading image")
  end
  return box_width, box_height
end

function outputter.drawRule (_, x, y, width, depth)
  cr:rectangle(x, y, width, depth)
  cr:fill()
end

function outputter.debugFrame (_, frame)
  cr:set_source_rgb(0.8, 0, 0)
  cr:set_line_width(0.5)
  cr:rectangle(frame:left(), frame:top(), frame:width(), frame:height())
  cr:stroke()
  cr:move_to(frame:left() - 10, frame:top() -2)
  cr:show_text(frame.id)
  cr:set_source_rgb(0, 0, 0)
end

function outputter:debugHbox (hbox, scaledWidth)
  cr:set_source_rgb(0.9, 0.9, 0.9)
  cr:set_line_width(0.5)
  local x, y = self:getCursor()
  cr:rectangle(x, y-(hbox.height), scaledWidth, hbox.height+hbox.depth)
  if (hbox.depth) then cr:rectangle(x, y-(hbox.height), scaledWidth, hbox.height); end
  cr:stroke()
  cr:set_source_rgb(0, 0, 0)
  cr:move_to(x, y)
end

return outputter

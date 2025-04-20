local base = require("outputters.base")

-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local lgi = require("lgi")
local cairo = lgi.cairo
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
outputter.extension = "pdf"

local started = false
local surface

function outputter:_init ()
   base._init(self)
end

function outputter:_ensureInit ()
   local fname = self:getOutputFilename()
   if not started then
      surface = cairo.PdfSurface.create(
         fname == "-" and "/dev/stdout" or fname,
         SILE.documentState.paperSize[1],
         SILE.documentState.paperSize[2]
      )
      cr = cairo.Context.create(surface)
      move = cr.move_to
      sgs = cr.show_glyph_string
   end
end

function outputter:newPage ()
   self:_ensureInit()
   cr:show_page()
end

function outputter:abort ()
   if started then
      surface:finish()
   end
end

function outputter:finish ()
   -- allows generation of empty PDFs
   self:_ensureInit()
   self:runHooks("prefinish")
   cr:show_page()
   surface:finish()
end

function outputter:getCursor ()
   return cursorX, cursorY
end

function outputter:setCursor (x, y, relative)
   self:_ensureInit()
   local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
   cursorX = offset.x + x
   cursorY = offset.y - y
   move(cr, cursorX, cursorY)
end

function outputter:setColor (color)
   self:_ensureInit()
   cr:set_source_rgb(color.r, color.g, color.b)
end

function outputter:drawHbox (value, _)
   self:_ensureInit()
   if not value then
      return
   end
   if value.pgs then
      sgs(cr, value.font, value.pgs)
   elseif value.text then
      cr:show_text(value.text)
   end
end

function outputter:setFont (options)
   self:_ensureInit()
   cr:select_font_face(options.font, options.style:lower() == "italic" and 1 or 0, options.weight > 100 and 0 or 1)
   cr:set_font_size(options.size)
end

function outputter:drawImage (src, x, y, width, height)
   self:_ensureInit()
   local image = cairo.ImageSurface.create_from_png(src)
   if not image then
      SU.error("Could not load image " .. src)
   end
   local src_width = image:get_width()
   local src_height = image:get_height()
   if not (src_width > 0) then
      SU.error("Something went wrong loading image " .. src)
   end
   cr:save()
   cr:set_source_surface(image, 0, 0)
   local p = cr:get_source()
   local matrix, sx, sy
   if width or height then
      if width > 0 then
         sx = src_width / width
      end
      if height > 0 then
         sy = src_height / height
      end
      matrix = cairo.Matrix.create_scale(sx or sy, sy or sx)
   else
      matrix = cairo.Matrix.create_identity()
   end
   matrix:translate(-x, -y)
   p:set_matrix(matrix)
   cr:paint()
   cr:restore()
end

function outputter:getImageSize (src)
   local box_width, box_height, err = imagesize.imgsize(src)
   if not box_width then
      SU.error(err .. " loading image")
   end
   return box_width, box_height
end

function outputter:drawRule (x, y, width, depth)
   self:_ensureInit()
   cr:rectangle(x, y, width, depth)
   cr:fill()
end

function outputter:debugFrame (frame)
   self:_ensureInit()
   cr:set_source_rgb(0.8, 0, 0)
   cr:set_line_width(0.5)
   cr:rectangle(frame:left(), frame:top(), frame:width(), frame:height())
   cr:stroke()
   cr:move_to(frame:left() - 10, frame:top() - 2)
   cr:show_text(frame.id)
   cr:set_source_rgb(0, 0, 0)
end

function outputter:debugHbox (hbox, scaledWidth)
   self:_ensureInit()
   cr:set_source_rgb(0.9, 0.9, 0.9)
   cr:set_line_width(0.5)
   local x, y = self:getCursor()
   cr:rectangle(x, y - hbox.height, scaledWidth, hbox.height + hbox.depth)
   if hbox.depth then
      cr:rectangle(x, y - hbox.height, scaledWidth, hbox.height)
   end
   cr:stroke()
   cr:set_source_rgb(0, 0, 0)
   cr:move_to(x, y)
end

-- untested
function outputter:drawRaw (literal)
   self:_ensureInit()
   cr:show_text(literal)
end

return outputter

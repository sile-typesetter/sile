local lgi = require("lgi");
local cairo = lgi.cairo
local pango = lgi.Pango

if (not SILE.outputters) then SILE.outputters = {} end

local cr
local move -- See https://github.com/pavouk/lgi/issues/48
local sgs

SILE.outputters.cairo = {
  init = function()
    local surface = cairo.PdfSurface.create(SILE.outputFilename, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    cr = cairo.Context.create(surface)
    move = cr.move_to
    sgs = cr.show_glyph_string
  end,
  newPage = function()
  	cr:show_page();
  end,
  finish = function() 
  end,
  setColor = function (self, color)
    cr:set_source_rgb(color.r, color.g, color.b)
  end,
  showGlyphString = function(f,pgs, options)
    sgs(cr, f,pgs)
  end,
  drawPNG = function (src, x,y,w,h)
    local image = cairo.ImageSurface.create_from_png(src)
    if not image then SU.error("Could not load image "..src) end
    local src_width = image:get_width()
    local src_height = image:get_height()
    if not (src_width > 0) then SU.error("Something went wrong loading image "..src) end
    cr:save()
    cr:set_source_surface(image, 0,0)
    local p = cr:get_source()
    local matrix, sx, sy
    if w or h then 
      if w > 0 then sx = src_width / w end
      if h > 0 then sy = src_height / h end
      matrix = cairo.Matrix.create_scale(sx or sy, sy or sx)
    else
      matrix = cairo.Matrix.create_identity()
    end
    matrix:translate(-x,-y)
    p:set_matrix(matrix)
    cr:paint()
    cr:restore()
  end,
  moveTo = function (x,y)
    move(cr, x,y)
  end,
  rule = function (x,y,w,d)
    cr:rectangle(x,y,w,d)
    cr:fill()
  end,
  debugFrame = function (self,f)
    cr:set_source_rgb(0.8,0,0)
    cr:set_line_width(0.5);
  	cr:rectangle(f:left(), f:top(), f:width(), f:height());
    cr:stroke();
  	cr:move_to(f:left() - 10, f:top() -2);
  	cr:show_text(f.id);
    cr:set_source_rgb(0,0,0);
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
    cr:set_source_rgb(0.9,0.9,0.9);
    cr:rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(hbox.height), scaledWidth, hbox.height+hbox.depth);
    if (hbox.depth) then cr:rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(hbox.height), scaledWidth, hbox.height); end
    cr:set_source_rgb(0,0,0);
  end
}

SILE.outputter = SILE.outputters.cairo
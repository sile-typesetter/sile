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
  moveTo = function (x,y)
    move(cr, x,y)
  end,
  rule = function (x,y,w,d)
    cr:rectangle(x,y,w,d)
    cr:fill()
  end,
  debugFrame = function (self,f)
    cr:set_line_width(0.5);
  	cr:rectangle(f:left(), f:top(), f:width(), f:height());
    cr:stroke();
  	cr:move_to(f:left(), f:top());
  	cr:show_text(f.id);
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
    cr:set_source_rgb(0.9,0.9,0.9);
    cr:rectangle(typesetter.state.cursorX, typesetter.state.cursorY-(hbox.height), scaledWidth, hbox.height+hbox.depth);
    if (hbox.depth) then cr:rectangle(typesetter.state.cursorX, typesetter.state.cursorY-(hbox.height), scaledWidth, hbox.height); end
    cr:set_source_rgb(0,0,0);
  end
}

SILE.outputter = SILE.outputters.cairo
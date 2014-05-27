local lgi = require("lgi");
local cairo = lgi.cairo
local pango = lgi.Pango

if (not SILE.outputters) then SILE.outputters = {} end

local cr

SILE.outputters.cairo = {
  init = function()
    local surface = cairo.PdfSurface.create(SILE.outputFilename, SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    cr = cairo.Context.create(surface)
  end,
  newPage = function()
  	cr:show_page();
  end,
  finish = function() 
  end,
  showGlyphString = function(f,pgs, options)
    -- Render underlines
    -- Render strikethroughs
    -- Render colors
    -- Render rises
    if (options.rise) then cr:rel_move_to(0, -options.rise) end
    if (options.color) then cr:set_source_rgb(options.color.r, options.color.g, options.color.b) end
    cr:show_glyph_string(f,pgs)
    --if (options.rise) then cr:rel_move_to(0,-options.rise*1024*0.75) end
  end,
  moveTo = function (x,y)
    cr:move_to(x,y)
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
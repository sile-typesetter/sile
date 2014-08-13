local lgi = require("lgi");
local cairo = lgi.cairo

SILE.registerCommand("img", function(options, content)
  local width =  SILE.parseComplexFrameDimension(options.width or 0,"w")
  local height = SILE.parseComplexFrameDimension(options.height or 0,"h")
  local src = options.src

  -- Wasteful but we need to know this at box construction time.
  local image = cairo.ImageSurface.create_from_png(src)
  if not image then SU.error("Could not load image "..src) end
  local box_width = image:get_width()
  local box_height = image:get_height()

  if not (box_width > 0) then SU.error("Something went wrong loading image "..src) end
  local sx, sy = 1,1
  if width > 0 or height > 0 then
    sx = width > 0 and box_width / width
    sy = height > 0 and box_height / height
    sx = sx or sy
    sy = sy or sx
  end

  SILE.typesetter:pushHbox({ 
    width= box_width / (sx),
    height= box_height / (sy),
    depth= 0,
    value= options.src,
    outputYourself= function (this, typesetter, line)
      SILE.outputter.drawPNG(this.value, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-this.height, this.width,this.height);
    
  end});

end, "Inserts the image specified with the <src> option in a box of size <width> by <height>");

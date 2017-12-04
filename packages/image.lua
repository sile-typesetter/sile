SILE.registerCommand("img", function(options, content)
  SU.required(options, "src", "including image file")
  local width =  SILE.parseComplexFrameDimension(options.width or 0,"w") or 0
  local height = SILE.parseComplexFrameDimension(options.height or 0,"h") or 0
  local src = SILE.resolveFile(options.src) or SU.error("Couldn't find file "..options.src)
  local box_width,box_height = SILE.outputter.imageSize(src)
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
    value= src,
    outputYourself= function (this, typesetter, line)
      SILE.outputter.drawImage(this.value, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-this.height, this.width,this.height)
      typesetter.frame:advanceWritingDirection(this.width)
  end})

end, "Inserts the image specified with the <src> option in a box of size <width> by <height>")

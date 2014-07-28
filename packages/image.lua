SILE.registerCommand("img", function(options, content)
  local width = options.width or 0
  local height = options.height or 0
  SILE.typesetter.pushHbox({ 
    width= SILE.parseComplexFrameDimension(width,"w"),
    height= SILE.parseComplexFrameDimension(height,"h"),
    depth= 0,
    value= options.src,
    outputYourself= function (typesetter, line) {
      SILE.cairo.drawPNG(this.value, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-this.height, this.width,this.height);
    }
  end);

end, "Inserts the image specified with the <src> option in a box of size <width> by <height>");

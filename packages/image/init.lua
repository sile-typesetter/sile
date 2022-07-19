local function registerCommands (class)

  class:registerCommand("img", function (options, _)
    SU.required(options, "src", "including image file")
    local width =  SILE.parseComplexFrameDimension(options.width or 0) or 0
    local height = SILE.parseComplexFrameDimension(options.height or 0) or 0
    local src = SILE.resolveFile(options.src) or SU.error("Couldn't find file "..options.src)
    local box_width, box_height = SILE.outputter:getImageSize(src)
    local sx, sy = 1, 1
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
      outputYourself= function (self, typesetter, _)
        SILE.outputter:drawImage(self.value, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-self.height, self.width, self.height)
        typesetter.frame:advanceWritingDirection(self.width)
    end})

  end, "Inserts the image specified with the <src> option in a box of size <width> by <height>")

end

return {
  registerCommands = registerCommands,
  documentation = [[
\begin{document}

As well as processing text, SILE can also include images.

Loading the \autodoc:package{image} package gives you the \autodoc:command{\img} command, fashioned
after the HTML equivalent. It takes the following parameters:
\autodoc:parameter{src=<file>} must be the path to an image file;
you may also give \autodoc:parameter{height} and/or \autodoc:parameter{width} parameters
to specify the output size of the image on the paper. If the size parameters
are not given, then the image will be output at its ‘natural’ size,
honoring its resolution if available.

\begin{note}
With the libtexpdf backend (the default), the images can be in JPEG, PNG,
EPS or PDF formats.
\end{note}

Here is a 200x243 pixel image output with \autodoc:command{\img[src=documentation/gutenberg.png]}.
The image has a claimed resolution of 100 pixels per inch, so ends up being 2 inches (144pt)
wide on the page:\par
\img[src=documentation/gutenberg.png]

\raggedright{
Here it is with (respectively)
\autodoc:command{\img[src=documentation/gutenberg.png,width=120pt]},
\autodoc:command{\img[src=documentation/gutenberg.png,height=200pt]}, and
\autodoc:command{\img[src=documentation/gutenberg.png,width=120pt,height=200pt]}:}

\img[src=documentation/gutenberg.png,width=120pt]
\img[src=documentation/gutenberg.png,height=200pt]
\img[src=documentation/gutenberg.png,width=120pt,height=200pt]

Notice that images are typeset on the baseline of a line of text, rather like
a very big letter.
\end{document}
]]}

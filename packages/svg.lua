local svg = require("svg")
local pdf = require("justenoughlibtexpdf")
local parser = require("core/opentype-parser")

local pushSVG = function (string, desiredHeight, em, drop)
  local figure, width, height = svg.svg_to_ps(string,em)
  local scalefactor = 1
  if desiredHeight then
    scalefactor = desiredHeight / height
    height = desiredHeight
    width = width * scalefactor
  end
  scalefactor = scalefactor * em / 72
  SILE.typesetter:pushHbox({
    value = nil,
    height = height,
    width = width,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.add_content("q")
      SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      local x,y = SILE.outputter.cursor()
      y = y - SILE.documentState.paperSize[2] + (drop and 0 or height)
      pdf.add_content(scalefactor.." 0 0 "..-(scalefactor).." "..x.." "..y.." cm")
      pdf.add_content(figure)
      pdf.add_content("Q")
      typesetter.frame:advanceWritingDirection(self.width)
    end
  })
end

SILE.registerCommand("include-svg-file", function (options, _)
  local fn = SU.required(options, "src", "filename")
  local height = options.height and SU.cast("measurement", options.height):absolute() or nil
  local density = options.density or 72
  local fh = io.open(fn)
  local inp = fh:read("*all")
  pushSVG(inp, height, density)
end)

SILE.registerCommand("svg-glyph", function(_, content)
  local fontoptions = SILE.font.loadDefaults({})
  local items = SILE.shaper:shapeToken(content[1], fontoptions)
  local face = SILE.shaper.getFace(fontoptions)
  parser.parseFont(face)
  if not face.font.svg then return SILE.process(content) end
  for i = 1, #items do
    local svg_data = parser.getSVG(face, items[i].gid)
    if svg_data then pushSVG(svg_data, fontoptions.size, 72, true) end
  end
end)

return {
  documentation = [[\begin{document}
This experimental package provides two commands.

The first is \code{\\include-svg-file[src=...,height=...,[density=...]{}]}.
This loads and parses an SVG file and attempts to render it in the current
document with the given height and density (which defaults to 72 ppi). For
example, the command \code{\\include-svg-file[src=examples/packages/smiley.svg,\goodbreak{}height=12pt]}
produces the following:

\include-svg-file[src=examples/packages/smiley.svg,height=12pt]

The second is \code{\\svg-glyph}. When the current font is set to an SVG font,
SILE does not currently render the SVG glyphs automatically. This command is
intended to be used as a means of eventually implementing SVG fonts; it retrieves
the SVG glyph provided and renders it.

The rendering is done with our own SVG drawing library; it is currently
very minimal, only handling lines, curves, strokes and fills. For a fuller
implementation, consider using a \code{converters} registration to render
your SVG file to PDF and include it on the fly.
\end{document}]]

}

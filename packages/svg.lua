local svg = require("svg")
local parser = require("core/opentype-parser")

local _drawSVG = function (svgdata, height, density, drop)
  local svgfigure, svgwidth, svgheight = svg.svg_to_ps(svgdata, density)
  local scalefactor = height and (height:tonumber() / svgheight) or 1
  local width = SILE.measurement(svgwidth * scalefactor)
  scalefactor = scalefactor * density / 72
  SILE.typesetter:pushHbox({
      value = nil,
      height = height,
      width = width,
      depth = 0,
      outputYourself = function (self, typesetter)
        SILE.outputter:drawSVG(svgfigure, typesetter.frame.state.cursorX, typesetter.frame.state.cursorY, self.width, drop and 0 or self.height, scalefactor)
        typesetter.frame:advanceWritingDirection(self.width)
      end
    })
end

SILE.registerCommand("include-svg-file", function (options, _)
  local fn = SU.required(options, "src", "filename")
  local height = options.height and SU.cast("measurement", options.height):absolute() or nil
  local density = options.density or 72
  local fh = io.open(fn)
  local svgdata = fh:read("*all")
  _drawSVG(svgdata, height, density)
end)

SILE.registerCommand("svg-glyph", function(_, content)
  local fontoptions = SILE.font.loadDefaults({})
  local items = SILE.shaper:shapeToken(content[1], fontoptions)
  local face = SILE.shaper.getFace(fontoptions)
  parser.parseFont(face)
  if not face.font.svg then return SILE.process(content) end
  for i = 1, #items do
    local svg_data = parser.getSVG(face, items[i].gid)
    if svg_data then
      _drawSVG(svg_data, fontoptions.size, 72, true)
    end
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

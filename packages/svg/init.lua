local base = require("packages.base")

local package = pl.class(base)
package._name = "svg"

local svg = require("svg")
local otparser = require("core.opentype-parser")

local _drawSVG = function (svgdata, width, height, density, drop)
  local scalefactor
  density = density or 72
  local ratiodensity =  72 / density
  print(ratiodensity)
  local svgfigure, svgwidth, svgheight = svg.svg_to_ps(svgdata, density)
  SU.debug("svg", string.format("PS: %s\n", svgfigure))
  if width and height then
    -- local aspect = svgwidth / svgheight
    SU.error("SILE cannot yet change SVG aspect ratios, specify either width or height but not both")
  elseif width then
    scalefactor = width:tonumber() / svgwidth
    height = SILE.measurement(svgheight * scalefactor)
    width = width
  elseif height then
    scalefactor = height:tonumber() / svgheight
    width = SILE.measurement(svgwidth * scalefactor)
    height = height * scalefactor
  else
    scalefactor = 1 * ratiodensity
    width = SILE.measurement(svgwidth * scalefactor)
    height = SILE.measurement(svgheight * scalefactor)
  end
  SU.debug("svg", string.format("SVG %s x %s (scaled %s) - %s x %s - density %s\n",
    tostring(width), tostring(height),
    tostring(scalefactor),
    tostring(svgwidth), tostring(svgheight),
    tostring(density)))

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

function package:registerRawHandlers ()

  self.class:registerRawHandler("svg", function(options, content)
    local svgdata = content[1]
    local width = options.width and SU.cast("measurement", options.width):absolute() or nil
    local height = options.height and SU.cast("measurement", options.height):absolute() or nil
    local density = options.density and SU.cast("integer", options.density)
    -- See issue #1375: svg.svg_to_ps() called in _drawSVG has a apparently a side effect
    -- on the internal representation of the Lua string and corrupts it.
    -- So as a workaround, for the original string to be able to be reused, we must get a
    -- copy... So let's force some stupid comment concatenation here.
    _drawSVG("<!-- copy -->"..svgdata, width, height, density)
  end)

end

function package:registerCommands ()

  self:registerCommand("svg", function (options, _)
    local fn = SU.required(options, "src", "filename")
    local width = options.width and SU.cast("measurement", options.width):absolute() or nil
    local height = options.height and SU.cast("measurement", options.height):absolute() or nil
    local density = options.density and SU.cast("integer", options.density)
    local svgfile, err = io.open(fn)
    if not svgfile then
      SU.error("Could not open SVG "..fn..": "..err)
      return
    end
    local svgdata = svgfile:read("*all")
    _drawSVG(svgdata, width, height, density)
  end)

  self:registerCommand("include-svg-file", function (_, _)
    SU.deprecated("\\include-svg-file", "\\svg", "0.10.10", "0.11.0")
  end, "Deprecated")

  self:registerCommand("svg-glyph", function(_, content)
    local fontoptions = SILE.font.loadDefaults({})
    local items = SILE.shaper:shapeToken(content[1], fontoptions)
    local face = SILE.shaper.getFace(fontoptions)
    otparser.parseFont(face)
    if not face.font.svg then return SILE.process(content) end
    for i = 1, #items do
      local svg_data = otparser.getSVG(face, items[i].gid)
      if svg_data then
        _drawSVG(svg_data, nil, fontoptions.size, 72, true)
      end
    end
  end)

end

package.documentation = [[
\begin{document}
This package provides two commands.

The first is \autodoc:command{\svg[src=<file>]}.
This loads and parses an SVG file and attempts to render it in the current document.
Optional \autodoc:parameter{width} or \autodoc:parameter{height} options will scale the SVG canvas to the given size calculated at a given \autodoc:parameter{density} option (which defaults to 72 ppi).
For example, the command \autodoc:command{\svg[src=packages/svg/smiley.svg,height=12pt]} produces the following:

\svg[src=packages/svg/smiley.svg,height=12pt]

The second is a more experimental \autodoc:command{\svg-glyph}.
When the current font is set to an SVG font, SILE does not currently render the SVG glyphs automatically.
This command is intended to be used as a means of eventually implementing SVG fonts; it retrieves the SVG glyph provided and renders it.

In both cases the rendering is done with our own SVG drawing library; it is currently very minimal, only handling lines, curves, strokes and fills.
For a fuller implementation, consider using a \autodoc:package{converters} registration to render your SVG file to PDF and include it on the fly.
\end{document}
]]

return package

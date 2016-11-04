local svg = require("svg")
local pdf = require("justenoughlibtexpdf")

SILE.registerCommand("include-svg-file", function (options,content)
  local fn = SU.required(options, "src", "filename")
  local fh = io.open(fn)
  local inp = fh:read("*all")
  local figure, width, height = svg.svg_to_ps(inp)
  SILE.typesetter:pushHbox({
    value = nil,
    height = height,
    width = width,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.add_content("q")
      local x,y = SILE.outputter.cursor()
      y = y - SILE.documentState.paperSize[2] + height
      pdf.add_content("1 0 0 -1 "..x.." "..y.." cm")
      pdf.add_content(figure)
      pdf.add_content("Q")
      typesetter.frame:advanceWritingDirection(self.width)
    end
  })
end)
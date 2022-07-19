local showHanmenYoko = function (frame)
  local g = frame:top()
  while g < frame:bottom() do
    SILE.outputter:drawRule(frame:left(), g - 0.25, frame:width(), 0.5)
    local l = frame:left()
    while l <= frame:right() do
      SILE.outputter:drawRule(l-0.25, g + frame.hanmen.gridsize - 0.25, 0.5, -frame.hanmen.gridsize)
      l = l + frame.hanmen.gridsize
    end
    g = g + frame.hanmen.gridsize
    SILE.outputter:drawRule(frame:left(), g - 0.25, frame:width(), 0.5)
    g = g + frame.hanmen.linegap
  end
end

local showHanmenTate = function (frame)
  local g = frame:right()
  while g > frame:left() do
    SILE.outputter:drawRule( g - 0.25, frame:top(), 0.5, -frame:height())
    local l = frame:top()
    while l < frame:bottom() do
      SILE.outputter:drawRule(g - frame.hanmen.gridsize - 0.25, l-0.25, frame.hanmen.gridsize, 0.5)
      l = l + frame.hanmen.gridsize
    end
    g = g - frame.hanmen.gridsize
    SILE.outputter:drawRule( g - 0.25, frame:top(), 0.5, -frame:height())
    g = g - frame.hanmen.linegap
  end
end

local declareHanmenFrame = function (self, id, spec)
  if spec then
    spec.id = id
  else
    spec = id
  end
  spec.hanmen = {
    gridsize = SU.required(spec, "gridsize", "declaring the kihonhanmen", "measurement"),
    linegap = SU.required(spec, "linegap", "declaring the kihonhanmen", "measurement"),
    linelength = SU.required(spec, "linelength", "declaring the kihonhanmen", "measurement"),
    linecount = SU.required(spec, "linecount", "declaring the kihonhanmen")
  }
  if spec.tate then
    spec.height = spec.hanmen.gridsize * spec.hanmen.linelength
    spec.width = spec.hanmen.gridsize * spec.hanmen.linecount +
                  spec.hanmen.linegap * ( spec.hanmen.linecount -1 )
  else
    spec.width = spec.hanmen.gridsize * spec.hanmen.linelength
    spec.height = spec.hanmen.gridsize * spec.hanmen.linecount +
                  spec.hanmen.linegap * ( spec.hanmen.linecount -1 )
  end
  local skip = spec.hanmen.linegap + spec.hanmen.gridsize
  SILE.settings:set("document.baselineskip", SILE.nodefactory.vglue(skip))
  SILE.settings:set("document.parskip", SILE.nodefactory.vglue())
  local frame = SILE.newFrame(spec, spec.tate and SILE.tateFramePrototype or SILE.framePrototype)
  if spec.id then
    self.pageTemplate.frames[spec.id] = frame
  end
  return frame
end

local function init (class, _)

  class:loadPackage("tate")

end

local function registerCommands (class)

  class:registerCommand("show-hanmen", function (_, _)
    local frame = SILE.typesetter.frame
    if not frame.hanmen then SU.error("show-hanmen called on a frame with no hanmen") end
    SILE.outputter:pushColor({r = 1, g= 0.9, b = 0.9 })
    if frame:writingDirection() == "TTB" then
      showHanmenTate(frame)
    else
      showHanmenYoko(frame)
    end
    SILE.outputter:popColor()
  end)

end

return {
  init = init,
  registerCommands = registerCommands,
  exports = {
    declareHanmenFrame = declareHanmenFrame
  },
  documentation = [[
\begin{document}
Japanese documents are traditionally typeset on a grid layout called a
\code{hanmen}, with each character essentially monospaced inside the
grid. (It’s like writing on graph paper.) The \autodoc:package{hanmenkyoshi} package
provides tools to Japanese class designers for creating hanmen frames with
correctly spaced grids. It also provides the \autodoc:command{\show-hanmen}
command for debugging the grid.

The name \em{hanmenkyoshi} is a terrible pun.
\end{document}
]]}

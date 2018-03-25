SILE.require("packages/tate")

local showHanmenYoko = function(f)
  local g = f:top()
  while g < f:bottom() do
    SILE.outputter.rule(f:left(), g - 0.25, f:width(), 0.5)
    local l = f:left()
    while l <= f:right() do
      SILE.outputter.rule(l-0.25, g + f.hanmen.gridsize - 0.25, 0.5, -f.hanmen.gridsize)
      l = l + f.hanmen.gridsize
    end
    g = g + f.hanmen.gridsize
    SILE.outputter.rule(f:left(), g - 0.25, f:width(), 0.5)
    g = g + f.hanmen.linegap
  end
end

local showHanmenTate = function(f)
  local g = f:right()
  while g > f:left() do
    SILE.outputter.rule( g - 0.25, f:top(), 0.5, -f:height())
    local l = f:top()
    while l < f:bottom() do
      SILE.outputter.rule(g - f.hanmen.gridsize - 0.25, l-0.25, f.hanmen.gridsize, 0.5)
      l = l + f.hanmen.gridsize
    end
    g = g - f.hanmen.gridsize
    SILE.outputter.rule( g - 0.25, f:top(), 0.5, -f:height())
    g = g - f.hanmen.linegap
  end
end


SILE.registerCommand("show-hanmen", function(options, content)
  local f = SILE.typesetter.frame
  if not f.hanmen then SU.error("show-hanmen called on a frame with no hanmen") end
  SILE.outputter:pushColor({r = 1, g= 0.9, b = 0.9 })
  if f:writingDirection() == "TTB" then
    showHanmenTate(f)
  else
    showHanmenYoko(f)
  end
  SILE.outputter:popColor()
end)

local declareHanmenFrame = function (self, id, spec)
  if id then
    spec.id = id
    SILE.frames[id] = nil
  else
    spec = id
  end
  spec.hanmen = {
    gridsize = SILE.toPoints(SU.required(spec, "gridsize", "declaring the kihonhanmen")),
    linegap = SILE.toPoints(SU.required(spec, "linegap", "declaring the kihonhanmen")),
    linelength = SILE.toPoints(SU.required(spec, "linelength", "declaring the kihonhanmen")),
    linecount = SILE.toPoints(SU.required(spec, "linecount", "declaring the kihonhanmen"))
  }
  if spec.tate then
    spec.height = (spec.hanmen.gridsize * spec.hanmen.linelength) .. "pt"
    spec.width = (spec.hanmen.gridsize * spec.hanmen.linecount +
                  spec.hanmen.linegap * ( spec.hanmen.linecount -1 )) .. "pt"
  else
    spec.width = (spec.hanmen.gridsize * spec.hanmen.linelength) .. "pt"
    spec.height = (spec.hanmen.gridsize * spec.hanmen.linecount +
                  spec.hanmen.linegap * ( spec.hanmen.linecount -1 )) .. "pt"
  end
  local skip = spec.hanmen.linegap + spec.hanmen.gridsize
  SILE.settings.set("document.baselineskip", SILE.nodefactory.newVglue(skip.."pt"))
  SILE.settings.set("document.parskip", SILE.nodefactory.newVglue("0pt"))
  local frame = SILE.newFrame(spec, spec.tate and SILE.tateFramePrototype or SILE.framePrototype)
  if spec.id then
    self.pageTemplate.frames[spec.id] = frame
  end
  return frame
end

return {
  init = function () end,
  exports = {
    declareHanmenFrame = declareHanmenFrame
  }
}

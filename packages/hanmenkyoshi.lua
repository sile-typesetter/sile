SILE.require("packages/tate")

local showHanmenYoko = function (frame)
  local g = frame:top()
  while g < frame:bottom() do
    SILE.outputter.rule(frame:left(), g - 0.25, frame:width(), 0.5)
    local l = frame:left()
    while l <= frame:right() do
      SILE.outputter.rule(l-0.25, g + frame.hanmen.gridsize - 0.25, 0.5, -frame.hanmen.gridsize)
      l = l + frame.hanmen.gridsize
    end
    g = g + frame.hanmen.gridsize
    SILE.outputter.rule(frame:left(), g - 0.25, frame:width(), 0.5)
    g = g + frame.hanmen.linegap
  end
end

local showHanmenTate = function (frame)
  local g = frame:right()
  while g > frame:left() do
    SILE.outputter.rule( g - 0.25, frame:top(), 0.5, -frame:height())
    local l = frame:top()
    while l < frame:bottom() do
      SILE.outputter.rule(g - frame.hanmen.gridsize - 0.25, l-0.25, frame.hanmen.gridsize, 0.5)
      l = l + frame.hanmen.gridsize
    end
    g = g - frame.hanmen.gridsize
    SILE.outputter.rule( g - 0.25, frame:top(), 0.5, -frame:height())
    g = g - frame.hanmen.linegap
  end
end


SILE.registerCommand("show-hanmen", function (_, _)
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

local declareHanmenFrame = function (self, id, spec)
  if id then
    spec.id = id
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

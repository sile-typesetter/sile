SILE.require("packages/tate")
SILE.registerCommand("show-hanmen", function(options, content)
  local f = SILE.typesetter.frame
  if not f.hanmen then SU.error("show-hanmen called on a frame with no hanmen") end
  
  -- Assuming horizontal for now
  SILE.outputter:pushColor({r = 1, g= 0.9, b = 0.9 })
  local g = f:top()
  while g < f:bottom() do
    SILE.outputter.rule(f:left(), g - 0.25, f:width(), 0.5)
    local l = f:left()
    while l <= f:right() do
      SILE.outputter.rule(l-0.25, g + f.hanmen.gridsize - 0.25, 0.5, f.hanmen.gridsize)
      l = l + f.hanmen.gridsize
    end
    g = g + f.hanmen.gridsize
    SILE.outputter.rule(f:left(), g - 0.25, f:width(), 0.5)
    g = g + f.hanmen.linegap
  end
  SILE.outputter:popColor()

end)

local declareHanmenFrame = function (self, id, spec)
  spec.id = id
  SILE.frames[id] = nil
  spec.hanmen = {
    gridsize = SILE.toPoints(SU.required(spec, "gridsize", "declaring the kihonhanmen")),
    linegap = SILE.toPoints(SU.required(spec, "linegap", "declaring the kihonhanmen")),
    linelength = SILE.toPoints(SU.required(spec, "linelength", "declaring the kihonhanmen"))
  }
  spec.width = (spec.hanmen.gridsize * spec.hanmen.linelength) .. "pt"
  local skip = spec.hanmen.linegap + spec.hanmen.gridsize
  SILE.settings.set("document.baselineskip", SILE.nodefactory.newVglue(skip.."pt"))
  SILE.settings.set("document.parskip", SILE.nodefactory.newVglue((spec.hanmen.linegap+0.5) .. "pt"))

  self.pageTemplate.frames[id] = SILE.newFrame(spec, spec.tate and SILE.tateFramePrototype or SILE.framePrototype)
end

return {
  init = function () end,
  exports = {
    declareHanmenFrame = declareHanmenFrame
  }
}
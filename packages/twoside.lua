local tp = "odd"

local mirrorMaster = function(_, existing, new)
  -- Frames in one master can't "see" frames in another, so we have to get creative
  -- XXX This knows altogether too much about the implementation of masters
  if not SILE.scratch.masters[new] then SILE.scratch.masters[new] = {frames={}} end
  if not SILE.scratch.masters[existing] then
    SU.error("Can't find master "..existing)
  end
  for name, frame in pairs(SILE.scratch.masters[existing].frames) do
    local newframe = pl.tablex.deepcopy(frame)
    if frame:isAbsoluteConstraint("right") then
      newframe.constraints.left = "100%pw-("..frame.constraints.right..")"
    end
    if frame:isAbsoluteConstraint("left") then
      newframe.constraints.right = "100%pw-("..frame.constraints.left..")"
    end
    SILE.scratch.masters[new].frames[name] = newframe
    if frame == SILE.scratch.masters[existing].firstContentFrame then
      SILE.scratch.masters[new].firstContentFrame = newframe
    end
  end
end

SILE.registerCommand("open-double-page", function()
  SILE.typesetter:leaveHmode()
  SILE.call("supereject")
  if SILE.documentState.documentClass:oddPage() then
    SILE.typesetter:typeset("")
    SILE.typesetter:leaveHmode()
    SILE.call("supereject")
  end
  SILE.typesetter:leaveHmode()
end)

return {
  init = function (class, args)
    class.oddPageMaster = args.oddPageMaster
    class.evenPageMaster = args.evenPageMaster
  end,
  exports = {
    oddPage = function () return tp == "odd" end,
    mirrorMaster = mirrorMaster,
    switchPage = function (self)
      if self:oddPage() then
        tp = "even"
        self.switchMaster(self.evenPageMaster)
      else
        tp = "odd"
        self.switchMaster(self.oddPageMaster)
      end
    end
  }, documentation = [[
\begin{document}
The \code{book} class described in chapter 4 sets up left and right mirrored
page masters; the \autodoc:package{twoside} package is responsible for swapping between
the two left and right frames, running headers and so on. It has no user-serviceable
parts.
\end{document}
]]
}

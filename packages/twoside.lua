local tp = "odd"
local mirrorMaster = function(class, new, existing)
  -- Frames in one master can't "see" frames in another, so we have to get creative
  -- XXX This knows altogether too much about the implementation of masters
  if not SILE.scratch.masters[new] then SILE.scratch.masters[new] = {frames={}} end
  if not SILE.scratch.masters[existing] then
    SU.error("Can't find master "..existing)
  end
  for name,frame in pairs(SILE.scratch.masters[existing].frames) do
    -- This seems to work although it is almost certainly too much magic
    SILE.scratch.masters[new].frames[name] = frame {
      left = function(frame)
        frame:solve()
        return SILE.frames.page:width() - frame.variables.right.value
      end,
      right = function(frame)
        frame:solve()
        return SILE.frames.page:width() - frame.variables.left.value
      end
    }

    if frame == SILE.scratch.masters[existing].firstContentFrame then
      SILE.scratch.masters[new].firstContentFrame = SILE.scratch.masters[new].frames[name]
    end
  end
end

return {
  init = function (class, args)
    class.oddPageMaster = args.oddPageMaster
    class.evenPageMaster = args.evenPageMaster
  end,
  exports = {
    oddPage = function (self) return tp == "odd" end,
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
  }
}
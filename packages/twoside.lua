return {
  init = function (class, args)
    class.oddPageFrameID = args.oddPageFrameID
    class.evenPageFrameID = args.evenPageFrameID
  end,
  exports = {
    oddPage = function (self) return (self.pageTemplate.firstContentFrame.id == self.oddPageFrameID) end,
    switchPage = function (self)
      if self:oddPage() then
        self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.evenPageFrameID]
      else
        self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.oddPageFrameID]
      end
    end
  }
}
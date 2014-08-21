return {
  init = function (class, args)
    class.oddPageFrameID = args.oddPageFrameID
    class.evenPageFrameID = args.evenPageFrameID
  end,
  exports = {
    oddPage = function (self) return (self.pageTemplate.firstContentFrame.id == self.oddPageFrameID) end,
    declareMirroredFrame = function(self, new, existing)
      self:declareFrame(new,
        { 
          width="width("..existing..")",
          height="height("..existing..")",
          top="top("..existing..")",
          left = "100% - right("..existing..")",
          right = "100% - left("..existing..")",
        }
      )
    end,
    switchPage = function (self)
      if self:oddPage() then
        self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.evenPageFrameID]
      else
        self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.oddPageFrameID]
      end
    end
  }
}
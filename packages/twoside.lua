local tp = "odd"
return {
  init = function (class, args)
    class.oddPageMaster = args.oddPageMaster
    class.evenPageMaster = args.evenPageMaster
  end,
  exports = {
    oddPage = function (self) return tp == "odd" end,
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
SILE.tateFramePrototype = SILE.framePrototype {
  moveX = function(self, amount)
    self.state.cursorY = self.state.cursorY + amount
  end,
  moveY = function(self, amount)
    self.state.cursorX = self.state.cursorX - amount
  end,
  newLine = function(self)
    self.state.cursorY = self:top()
  end,
  direction = "TTB",
  init = function(self)
    SILE.framePrototype.init(self)
    self.state.cursorX = self:right()
  end,
  enterHooks = { function (self)
    self.state.oldBreak = SILE.settings.get("typesetter.breakwidth")
    SILE.typesetter.oldPagetarget = SILE.typesetter.pageTarget
    SILE.settings.set("typesetter.breakwidth", SILE.length.new({length = self:height() }))
    SILE.typesetter.pageTarget = function(self)
      return self.frame:width()
    end
    end
  },
  leaveHooks = { function (self)
    SILE.settings.set("typesetter.breakwidth", self.state.oldBreak)
    SILE.typesetter.pageTarget = SILE.typesetter.oldPagetarget
  end
  }
}

SILE.newTateFrame = function ( spec )
  return SILE.newFrame(spec, SILE.tateFramePrototype)
end

SILE.registerCommand("tate-frame", function (options, content)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newTateFrame(options);
    end, "Declares (or re-declares) a frame on this page.")

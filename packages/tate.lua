local pdf = require("justenoughlibtexpdf")

SILE.tateFramePrototype = SILE.framePrototype {
  moveX = function(self, amount)
    self.state.cursorY = self.state.cursorY + amount
  if type(amount) == "table" then SU.error("Table passed to moveX", 1) end
  end,
  moveY = function(self, amount)
    self.state.cursorX = self.state.cursorX - amount
  if type(amount) == "table" then SU.error("Table passed to moveY", 1) end
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
    self.oldtypesetter = SILE.typesetter
    self.state.oldBreak = SILE.settings.get("typesetter.breakwidth")
    SILE.settings.set("typesetter.breakwidth", SILE.length.new({length = self:height() }))
    pdf.setdirmode(1)
    SILE.typesetter.pageTarget = function(self)
      return self.frame:width()
    end
    SILE.typesetter.leadingFor = function(self, v)
      v.height = SILE.toPoints("1zw")
      return SILE.settings.get("document.parskip")
    end
    SILE.typesetter.breakIntoLines = SILE.require("packages/break-firstfit")
  end
  },
  leaveHooks = { function (self)
    SILE.settings.set("typesetter.breakwidth", self.state.oldBreak)
    SILE.typesetter = self.oldtypesetter
    pdf.setdirmode(0)
  end
  }
}

SILE.newTateFrame = function ( spec )
  return SILE.newFrame(spec, SILE.tateFramePrototype)
end

SILE.registerCommand("tate-frame", function (options, content)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newTateFrame(options);
    end, "Declares (or re-declares) a frame on this page.")

local swap = function (x)
  local w = x.width
  x.width = SILE.length.new({}) + x.height
  x.height = type(w) == "table" and w.length or w
end

local outputLatinInTate = function (self, typesetter, line)
  -- My baseline moved
  typesetter.frame:moveX(SILE.toPoints("-1zw"))
  typesetter.frame:moveY(SILE.toPoints("0.25zw"))

  local horigin = typesetter.frame.state.cursorX
  local vorigin = -typesetter.frame.state.cursorY
  pdf:gsave()
  pdf.setmatrix(1,0,0,1,horigin,vorigin)
  pdf.setmatrix(0, -1, 1, 0, 0, 0)
  pdf.setmatrix(1,0,0,1,-horigin,-vorigin)
  pdf.setdirmode(0)
  self:oldOutputYourself(typesetter,line)
  pdf.setdirmode(1)
  pdf:grestore()
  typesetter.frame.state.cursorY = -vorigin
  typesetter.frame:moveX(self.height)
  -- My baseline moved
  typesetter.frame:moveX(SILE.toPoints("1zw") )
  typesetter.frame:moveY(- SILE.toPoints("0.25zw"))
end


local outputTateChuYoko = function (self, typesetter, line)
  -- My baseline moved

  local vorigin = -typesetter.frame.state.cursorY
  typesetter.frame:moveX(self.height)
  typesetter.frame:moveY(0.5 * self.width.length)
  pdf.setdirmode(0)
  self:oldOutputYourself(typesetter,line)
  pdf.setdirmode(1)
  typesetter.frame.state.cursorY = -vorigin
  typesetter.frame:moveX(self.height)
  -- My baseline moved
  -- typesetter.frame:moveX(SILE.toPoints("1zw") )
  typesetter.frame:moveY(-0.5 * self.width.length)
end
-- Eventually will be automatically called by script detection, but for now
-- called manually
SILE.registerCommand("latin-in-tate", function (options, content)
  local nodes
  local oldT = SILE.typesetter
  local prevDirection = oldT.frame.direction
  if prevDirection ~= "TTB" then return SILE.process(content) end
  SILE.require("packages/rotate")
  SILE.settings.temporarily(function()
    local latinT = SILE.defaultTypesetter {}
    latinT.frame = oldT.frame
    latinT:initState()
    SILE.typesetter = latinT
    SILE.settings.set("document.language", "xx")
    SILE.settings.set("font.direction", "LTR")
    SILE.process(content)
    nodes = SILE.typesetter.state.nodes
    for i=1,#nodes do
      if nodes[i]:isUnshaped() then nodes[i] = nodes[i]:shape() end
    end
    SILE.typesetter.frame.direction = prevDirection
  end)
  SILE.typesetter = oldT
  SILE.typesetter:pushGlue({
    width = SILE.length.new({length = SILE.toPoints("0.5zw"),
                             stretch = SILE.toPoints("0.25zw"),
                              shrink = SILE.toPoints("0.25zw")
                            })
  })
  for i = 1,#nodes do
    if SILE.typesetter.frame.direction ~= "TTB" then
      SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
    elseif nodes[i]:isGlue() then
      nodes[i].width = nodes[i].width
      SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
    elseif nodes[i].width > 0 then
      SILE.call("hbox", {}, function ()
        SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
      end)
      local n = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
      n.oldOutputYourself = n.outputYourself
      n.outputYourself = outputLatinInTate
      swap(n)
    end
  end
end, "Typeset rotated Western text in vertical Japanese")

SILE.registerCommand("tate-chu-yoko", function (options, content)
  if SILE.typesetter.frame.direction ~= "TTB" then return SILE.process(content) end
  SILE.typesetter:pushGlue({
    width = SILE.length.new({length = SILE.toPoints("0.5zw"),
                             stretch = SILE.toPoints("0.25zw"),
                              shrink = SILE.toPoints("0.25zw")
                            })
  })
  SILE.settings.temporarily(function()
    SILE.settings.set("document.language", "xx")
    SILE.settings.set("font.direction", "LTR")
    SILE.call("hbox", {}, content)
    local n = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
    n.oldOutputYourself = n.outputYourself
    n.outputYourself = outputTateChuYoko
  end)  
  SILE.typesetter:pushGlue({
    width = SILE.length.new({length = SILE.toPoints("0.5zw"),
                             stretch = SILE.toPoints("0.25zw"),
                              shrink = SILE.toPoints("0.25zw")
                            })
  })

end)
local pdf = require("justenoughlibtexpdf")

SILE.tateFramePrototype = SILE.framePrototype {
  direction = "TTB-RTL",
  enterHooks = { function (self)
    self.oldtypesetter = SILE.typesetter
    SILE.typesetter.leadingFor = function(self, v)
      v.height = SILE.toPoints("1zw")
      return SILE.settings.get("document.parskip")
    end
    SILE.typesetter.breakIntoLines = SILE.require("packages/break-firstfit")
  end
  },
  leaveHooks = { function (self)
    SILE.typesetter = self.oldtypesetter
  end
  }
}

SILE.newTateFrame = function ( spec )
  return SILE.newFrame(spec, SILE.tateFramePrototype)
end

SILE.registerCommand("tate-frame", function (options, content)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newTateFrame(options)
    end, "Declares (or re-declares) a frame on this page.")

local swap = function (x)
  local w = x.width
  x.width = SILE.length.new({}) + x.height
  x.height = type(w) == "table" and w.length or w
end

local outputLatinInTate = function (self, typesetter, line)
  -- My baseline moved
  typesetter.frame:advanceWritingDirection(SILE.toPoints("-0.5zw"))
  typesetter.frame:advancePageDirection(SILE.toPoints("0.25zw"))

  local horigin = typesetter.frame.state.cursorX
  local vorigin = -typesetter.frame.state.cursorY
  self:oldOutputYourself(typesetter,line)
  typesetter.frame.state.cursorY = -vorigin
  typesetter.frame:advanceWritingDirection(self:lineContribution())
  -- My baseline moved
  typesetter.frame:advanceWritingDirection(SILE.toPoints("0.5zw") )
  typesetter.frame:advancePageDirection(- SILE.toPoints("0.25zw"))
end


local outputTateChuYoko = function (self, typesetter, line)
  -- My baseline moved
  local em = SILE.toPoints("1zw")
  typesetter.frame:advanceWritingDirection(-(em) + em/4 - self:lineContribution()/2)
  typesetter.frame:advancePageDirection(2*self.height - self.width.length/2)
  self:oldOutputYourself(typesetter,line)
  typesetter.frame:advanceWritingDirection(-self:lineContribution()*1.5+self.height*3/4)

end
-- Eventually will be automatically called by script detection, but for now
-- called manually
SILE.registerCommand("latin-in-tate", function (options, content)
  local nodes
  local oldT = SILE.typesetter
  local prevDirection = oldT.frame.direction
  if oldT.frame:writingDirection() ~= "TTB" then return SILE.process(content) end
  SILE.require("packages/rotate")
  SILE.settings.temporarily(function()
    local latinT = SILE.defaultTypesetter {}
    latinT.frame = oldT.frame
    latinT:initState()
    SILE.typesetter = latinT
    SILE.settings.set("document.language", "und")
    SILE.settings.set("font.direction", "LTR")
    SILE.process(content)
    nodes = SILE.typesetter.state.nodes
    SILE.typesetter:shapeAllNodes(nodes)
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
    if SILE.typesetter.frame:writingDirection() ~= "TTB" then
      SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
    elseif nodes[i]:isGlue() then
      nodes[i].width = nodes[i].width
      SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
    elseif SILE.length.make(nodes[i]:lineContribution()).length > 0 then
      SILE.call("hbox", {}, function ()
        SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes+1] = nodes[i]
      end)
      local n = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
      n.oldOutputYourself = n.outputYourself
      n.outputYourself = outputLatinInTate
      n.misfit = true
    end
  end
end, "Typeset rotated Western text in vertical Japanese")

SILE.registerCommand("tate-chu-yoko", function (options, content)
  if SILE.typesetter.frame:writingDirection() ~= "TTB" then return SILE.process(content) end
  -- SILE.typesetter:pushGlue({
  --   width = SILE.length.new({length = SILE.toPoints("0.5zw"),
  --                            stretch = SILE.toPoints("0.25zw"),
  --                             shrink = SILE.toPoints("0.25zw")
  --                           })
  -- })
  SILE.settings.temporarily(function()
    SILE.settings.set("document.language", "und")
    SILE.settings.set("font.direction", "LTR")
    SILE.call("rotate",{angle =-90}, function ()
      SILE.call("hbox", {}, content)
      local n = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
      n.misfit = true
      n.oldOutputYourself = n.outputYourself
      n.outputYourself = outputTateChuYoko
    end)

  end)
  -- SILE.typesetter:pushGlue({
  --   width = SILE.length.new({length = SILE.toPoints("0.5zw"),
  --                            stretch = SILE.toPoints("0.25zw"),
  --                             shrink = SILE.toPoints("0.25zw")
  --                           })
  -- })

end)

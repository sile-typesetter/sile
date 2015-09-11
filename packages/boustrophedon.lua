SILE.tokenizers.grc = function(text)
  local chunks = SU.splitUtf8(text)
  return coroutine.wrap(function()
    for i = 1,#chunks do
      coroutine.yield({ string = chunks[i] })
      coroutine.yield({ node = SILE.nodefactory.newPenalty({ penalty = 0 }) })
    end
  end)
end

local swap = SILE.nodefactory.newVbox({})
swap.outputYourself = function(self,typesetter,line)
  typesetter.frame.direction = typesetter.frame.direction == "LTR-TTB" and "RTL-TTB" or "LTR-TTB"
  typesetter.frame:newLine()
end

SILE.registerCommand("boustrophedon", function (o,c)
  SILE.typesetter.boxUpNodes = function(self)
    local vboxlist = SILE.defaultTypesetter.boxUpNodes(self)
    local nl = {}
    for i=1,#vboxlist do
      nl[#nl+1] = vboxlist[i]
      if nl[#nl]:isVbox() then nl[#nl+1] = swap end
    end
    return nl
  end
  SILE.call("thisframeRTL")
  SILE.process(c)
  SILE.typesetter:leaveHmode()
  SILE.typesetter.boxUpNodes = SILE.defaultTypesetter.boxUpNodes
end)
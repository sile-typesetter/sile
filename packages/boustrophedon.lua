SILE.hyphenator.languages.grc = { patterns={} }
SILE.nodeMakers.grc = SILE.nodeMakers.unicode {
  iterator = function (self, items)
    return coroutine.wrap(function ()
      self:init()
      for i = 1, #items do
        self:addToken(items[i].text, items[i])
        self:makeToken()
        self:makePenalty()
        coroutine.yield(SILE.nodefactory.newGlue("0pt plus 2pt"))
      end
    end)
  end
}

local swap = SILE.nodefactory.newVbox({})
swap.outputYourself = function (self, typesetter, line)
  typesetter.frame.direction = typesetter.frame.direction == "LTR-TTB" and "RTL-TTB" or "LTR-TTB"
  typesetter.frame:newLine()
end

SILE.registerCommand("boustrophedon", function (o, c)
  SILE.typesetter:leaveHmode()
  local saveBoxup = SILE.typesetter.boxUpNodes
  local swaps = 0
  SILE.typesetter.boxUpNodes = function (self)
    local vboxlist = saveBoxup(self)
    local nl = {}
    for i = 1, #vboxlist do
      nl[#nl+1] = vboxlist[i]
      if nl[#nl]:isVbox() then
        nl[#nl+1] = swap
        swaps = swaps + 1
      end
    end
    return nl
  end
  SILE.process(c)
  SILE.typesetter:leaveHmode()
  SILE.typesetter.boxUpNodes = saveBoxup
  if swaps % 2 == 1 then
    SILE.typesetter:pushVbox(swap)
  end
end)

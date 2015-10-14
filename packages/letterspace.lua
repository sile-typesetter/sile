SILE.settings.declare({
  name = "document.letterspaceglue",
  type = "Kern or nil",
  default = SILE.nodefactory.newKern("1pt minus 1pt"),
  help = "Skip to be added in between letters"
})

require("char-def")
local chardata  = characters.data

SILE.nodeMakers.letterSpace = SILE.nodeMakers.base {
  makeLetterSpaceGlue = function(self)
    if self.lastnode ~= "glue" then
      coroutine.yield(SILE.nodefactory.newKern(SILE.settings.get("document.letterspaceglue")))
    end
    self.lastnode = "glue"
  end,
  iterator = function (self, items)
    self:init()
    return coroutine.wrap(function()
      for i = 1,#items do item = items[i]
        local char = items[i].text
        local cp = SU.codepoint(char)
        local thistype = chardata[cp] and chardata[cp].linebreak
        if chardata[cp] and thistype == "sp" then
          self:makeToken()
          self:makeGlue()
        elseif chardata[cp] and (thistype == "ba" or  thistype == "zw") then
          self:addToken(char,item)
          self:makeToken()
          self:makePenalty(0)
        elseif lasttype and (thistype ~= lasttype and thistype ~= "cm") then
          self:makeToken()
          self:makeLetterSpaceGlue()
          self:addToken(char,item)
        else
          self:makeToken()
          self:makeLetterSpaceGlue()
          self:addToken(char,item)
        end
        if thistype ~= "cm" then lasttype = chardata[cp] and chardata[cp].linebreak end
      end
      self:makeToken()
    end)
  end
}

SILE.registerCommand("letterspace", function (o,c)
  local cnn = SILE.shaper.createNnodes
  SILE.shaper.createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    if #items < 1 then return {} end
    local nodeMaker = SILE.nodeMakers.letterSpace
    local nodes = {}
    for node in (nodeMaker { options=options }):iterator(items, token) do
      nodes[#nodes+1] = node
    end
    return nodes
  end
  SILE.process(c)
  SILE.typesetter:leaveHmode()
  SILE.shaper.createNnodes = cnn
end)
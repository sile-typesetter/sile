require("char-def")
local chardata  = characters.data

SILE.nodeMakers.base = std.object {
  makeToken = function(self)
    if #self.contents>0 then
      coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
      self.contents = {} ; self.token = "" ; self.lastnode = "nnode"
    end
  end,
  addToken = function (self, char, item)
    self.token = self.token .. char
    self.contents[#self.contents+1] = item
  end,
  makeGlue = function(self)
    if self.lastnode ~= "glue" then
      coroutine.yield(SILE.shaper:makeSpaceNode(self.options))
    end
    self.lastnode = "glue"
  end,
  makePenalty = function (self,p)
    coroutine.yield( SILE.nodefactory.newPenalty({ penalty = p or 0 }) )
    self.lastnode = "penalty"
  end,
  init = function (self)
    self.contents = {}
    self.token = ""
    self.lastnode = ""
  end,
  iterator = function (self,items)
    SU.error("Abstract function nodemaker:iterator called",1)
  end
}

SILE.nodeMakers.unicode = SILE.nodeMakers.base {
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
          self:addToken(char,item)
        else
          self:addToken(char,item)
        end
        if thistype ~= "cm" then lasttype = chardata[cp] and chardata[cp].linebreak end
      end
      self:makeToken()
    end)
  end
}

pcall( function () icu = require("justenoughicu") end)
if icu then
  SILE.nodeMakers.unicode = SILE.nodeMakers.base {
    iterator = function (self, items)
      local fulltext = ""
      for i = 1,#items do item = items[i]
        fulltext = fulltext .. items[i].text
      end
      local chunks = {icu.breakpoints(fulltext)}
      self:init()
      return coroutine.wrap(function()
        local ptr = 1
        for i = 1,(#chunks) do local chunk = chunks[i]
          if chunk.token:match("^%s+$") then
            local t = ""
            while t ~= chunk.token do
              if ptr > #items then SU.error("Couldn't resolve "..chunk.token.." in input") end
              t = t .. items[ptr].text
              ptr = ptr +1
            end
            self:makeToken()
            self:makeGlue()
          elseif chunk.type == "line" then
            local t = ""
            while t ~= chunk.token do
              if ptr > #items then SU.error("Couldn't resolve "..chunk.token.." in input") end
              t = t .. items[ptr].text
              self:addToken(items[ptr].text,items[ptr])
              ptr = ptr +1
            end
            self:makeToken()
            self:makePenalty(chunk.subtype == "soft" and 0 or -1000)
          else
            local t = ""
            while t ~= chunk.token do
              if ptr > #items then SU.error("Couldn't resolve "..chunk.token.." in input") end
              t = t .. items[ptr].text
              self:addToken(items[ptr].text,items[ptr])
              ptr = ptr +1
            end
          end
        end
        self:makeToken()
      end)
    end
  }
end
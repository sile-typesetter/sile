require("char-def")
local chardata  = characters.data
icu = require("justenoughicu")

SILE.nodeMakers.base = std.object {
  makeToken = function(self)
    if #self.contents>0 then
      coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
      SU.debug("tokenizer", "Token: "..self.token)
      self.contents = {} ; self.token = "" ; self.lastnode = "nnode"
    end
  end,
  makeLetterSpaceGlue = function(self)
    if self.lastnode ~= "glue" then
      if SILE.settings.get("document.letterspaceglue") then
        local w = SILE.settings.get("document.letterspaceglue").width
        coroutine.yield(SILE.nodefactory.newKern({ width = w }))
      end
    end
    self.lastnode = "glue"
  end,
  addToken = function (self, char, item)
    self.token = self.token .. char
    self.contents[#self.contents+1] = item
  end,
  makeGlue = function(self,item)
    if SILE.settings.get("typesetter.obeyspaces") or self.lastnode ~= "glue" then
      coroutine.yield(SILE.shaper:makeSpaceNode(self.options, item))
    end
    self.lastnode = "glue"
  end,
  makePenalty = function (self,p)
    if self.lastnode ~= "penalty" and self.lastnode ~= "glue" then
      coroutine.yield( SILE.nodefactory.newPenalty({ penalty = p or 0 }) )
    end
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
  isWordType = { cm = true },
  isSpaceType = { sp = true },
  isBreakingType = { ba = true, zw = true },
  dealWith = function (self, item)
    local char = item.text
    local cp = SU.codepoint(char)
    local thistype = chardata[cp] and chardata[cp].linebreak
    if chardata[cp] and self.isSpaceType[thistype] then
      self:makeToken()
      self:makeGlue(item)
    elseif chardata[cp] and self.isBreakingType[thistype] then
      self:addToken(char,item)
      self:makeToken()
      self:makePenalty(0)
    elseif lasttype and (thistype and thistype ~= lasttype and not self.isWordType[thistype]) then
      self:makeToken()
      self:addToken(char,item)
    else
      if SILE.settings.get("document.letterspaceglue") then
        self:makeToken()
        self:makeLetterSpaceGlue()
      end
      self:addToken(char,item)
    end
    if not self.isWordType[thistype] then lasttype = chardata[cp] and chardata[cp].linebreak end
  end,
  iterator = function (self, items)
    local fulltext = ""
    local ics = SILE.settings.get("document.letterspaceglue")
    for i = 1,#items do item = items[i]
      fulltext = fulltext .. items[i].text
    end
    local chunks = {icu.breakpoints(fulltext, self.options.language)}
    self:init()
    table.remove(chunks,1)
    return coroutine.wrap(function()
      -- Special-case initial glue
      local i = 1
      while i <= #items do item = items[i]
        local char = item.text
        local cp = SU.codepoint(char)
        local thistype = chardata[cp] and chardata[cp].linebreak
        if thistype == "sp" then self:makeGlue(item) else break end
        i = i + 1
      end
      -- And now onto the real thing
      for i = i,#items do item = items[i]
        local char = items[i].text
        local cp = SU.codepoint(char)
        if chunks[1] and (items[i].index >= chunks[1].index) then
          -- There's a break here
          local thistype = chardata[cp] and chardata[cp].linebreak
          local bp = chunks[1]
          while chunks[1] and items[i].index >= chunks[1].index do
            table.remove(chunks,1)
          end
          if bp.type == "word" then
            if chardata[cp] and thistype == "sp" then
              -- Spacing word break
              self:makeToken()
              self:makeGlue(item)
            else -- a word break which isn't a space
              self:makeToken()
              self:addToken(char,item)
            end
          elseif bp.type == "line" then
            if chardata[cp] and thistype == "sp" then
              self:makeToken()
              self:makeGlue(item)
            else
              -- Line break
              self:makeToken()
              self:makePenalty(bp.subtype == "soft" and 0 or -1000)
              self:addToken(char,item)
            end
          end
        else
          local thistype = chardata[cp] and chardata[cp].linebreak
          if ics then
            self:makeToken()
            self:makeLetterSpaceGlue()
          end
          if chardata[cp] and thistype == "sp" then
            self:makeToken()
            self:makeGlue(item)
          else
            self:addToken(char,item)
          end
        end
      end
      if ics then self:makeLetterSpaceGlue() end
      self:makeToken()
    end)
  end
}
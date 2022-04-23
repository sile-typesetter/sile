local icu = require("justenoughicu")

local chardata = require("char-def")

SILE.nodeMakers.base = pl.class({

    _init = function (self, options)
      self.contents = {}
      self.options = options
      self.token = ""
      self.lastnode = false
      -- The whole lasttype logic below was wrong and broken, and confusing. See #687 and #1297
      -- self.lasttype = false
    end,

    makeToken = function (self)
      if #self.contents > 0 then
        coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
        SU.debug("tokenizer", "Token: "..self.token)
        self.contents = {}
        self.token = ""
        self.lastnode = "nnode"
      end
    end,

    addToken = function (self, char, item)
      self.token = self.token .. char
      table.insert(self.contents, item)
    end,

    makeGlue = function (self, item)
      if SILE.settings.get("typesetter.obeyspaces") or self.lastnode ~= "glue" then
        SU.debug("tokenizer", "Space node")
        coroutine.yield(SILE.shaper:makeSpaceNode(self.options, item))
      end
      self.lastnode = "glue"
    end,

    makePenalty = function (self, p)
      if self.lastnode ~= "penalty" and self.lastnode ~= "glue" then
        coroutine.yield( SILE.nodefactory.penalty({ penalty = p or 0 }) )
      end
      self.lastnode = "penalty"
    end,

    iterator = function (_, _)
      SU.error("Abstract function nodemaker:iterator called", true)
    end,

    charData = function (_, char)
      local cp = SU.codepoint(char)
      if not chardata[cp] then return {} end
      return chardata[cp]
    end,

    isPunctuation = function (self, char)
      return self.isPunctuationType[self:charData(char).category]
    end,

    isSpace = function (self, char)
      return self.isSpaceType[self:charData(char).linebreak]
    end,

    isBreaking = function (self, char)
      return self.isBreakingType[self:charData(char).linebreak]
    end,
    isQuote = function (self, char)
      return self.isQuoteType[self:charData(char).linebreak]
    end

  })

SILE.nodeMakers.unicode = pl.class(SILE.nodeMakers.base)

SILE.nodeMakers.unicode.isWordType = { cm = true }
SILE.nodeMakers.unicode.isSpaceType = { sp = true }
SILE.nodeMakers.unicode.isBreakingType = { ba = true, zw = true }
SILE.nodeMakers.unicode.isPunctuationType = { po = true }
SILE.nodeMakers.unicode.isQuoteType = {} -- quote linebreak category is ambiguous depending on the language

function SILE.nodeMakers.unicode:dealWith (item)
  local char = item.text
  -- local cp = SU.codepoint(char)
  -- local thistype = chardata[cp] and chardata[cp].linebreak
  if self:isSpace(item.text) then
    self:makeToken()
    self:makeGlue(item)
  elseif self:isBreaking(item.text) then
    self:addToken(char, item)
    self:makeToken()
    self:makePenalty(0)
  elseif self:isQuote(item.text) then
    self:addToken(char, item)
    self:makeToken()
  -- elseif self.lasttype and (thistype and thistype ~= self.lasttype and not self.isWordType[thistype]) then
  --   self:makeToken()
  --   self:addToken(char, item)
  else
    self:letterspace()
    self:addToken(char, item)
  end
  -- if not self.isWordType[thistype] then self.lasttype = chardata[cp] and chardata[cp].linebreak end
  -- self.lasttype = thistype
end

function SILE.nodeMakers.unicode:handleInitialGlue (items)
  local i = 1
  while i <= #items do
    local item = items[i]
    if self:isSpace(item.text) then self:makeGlue(item) else break end
    i = i + 1
  end
  return i, items
end

function SILE.nodeMakers.unicode:letterspace ()
  if not SILE.settings.get("document.letterspaceglue") then return end
  if self.token then self:makeToken() end
  if self.lastnode and self.lastnode ~= "glue" then
    local w = SILE.settings.get("document.letterspaceglue").width
    SU.debug("tokenizer", "Letter space glue: " .. tostring(w))
    coroutine.yield(SILE.nodefactory.kern({ width = w }))
    self.lastnode = "glue"
  end
end

function SILE.nodeMakers.unicode.isICUBreakHere (_, chunks, item)
  return chunks[1] and (item.index >= chunks[1].index)
end

function SILE.nodeMakers.unicode:handleICUBreak (chunks, item)
  -- The ICU library has told us there is a breakpoint at
  -- this index. We need to...
  local bp = chunks[1]
  -- ... remove this breakpoint (and any out of order ones)
  -- from the ICU breakpoints array so that chunks[1] is
  -- the next index point for comparison against the string...
  while chunks[1] and item.index >= chunks[1].index do
    table.remove(chunks, 1)
  end
  -- ...decide which kind of breakpoint we have here and
  -- handle it appropriately.
  if bp.type == "word" then
    self:handleWordBreak(item)
  elseif bp.type == "line" then
    self:handleLineBreak(item, bp.subtype)
  end
  return chunks
end

function SILE.nodeMakers.unicode:handleWordBreak (item)
  self:makeToken()
  if self:isSpace(item.text) then
    -- Spacing word break
    self:makeGlue(item)
  else -- a word break which isn't a space
    self:addToken(item.text, item)
  end
end

function SILE.nodeMakers.unicode:handleLineBreak (item, subtype)
  -- Because we are in charge of paragraphing, we
  -- will override space-type line breaks, and treat
  -- them just as ordinary word spaces.
  if self:isSpace(item.text) then
    self:handleWordBreak(item)
    return
  end
  -- But explicit line breaks we will turn into
  -- soft and hard breaks.
  self:makeToken()
  self:makePenalty(subtype == "soft" and 0 or -1000)
  self:addToken(item.text, item)
end

function SILE.nodeMakers.unicode:iterator (items)
  local fulltext = ""
  for i = 1, #items do
    fulltext = fulltext .. items[i].text
  end
  local chunks = { icu.breakpoints(fulltext, self.options.language) }
  table.remove(chunks, 1)
  return coroutine.wrap(function ()
    local i
    i, self.items = self:handleInitialGlue(items)
    for j = i, #items do
      self.i = j
      self.item = self.items[self.i]
      if self:isICUBreakHere(chunks, self.item) then
        chunks = self:handleICUBreak(chunks, self.item)
      else
        self:dealWith(self.item)
      end
    end
    self:makeToken()
  end)
end

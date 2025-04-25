local base = require("languages.base-nodemaker")

local icu = require("justenoughicu")
local chardata = require("char-def")

local nodemaker = pl.class(base)
nodemaker._name = "unicode"

function nodemaker:_init (language, options)
   base._init(self, language, options)
   self.breakingTypes = { ba = true, zw = true }
   self.puctuationTypes = { po = true }
   self.quoteTypes = {} -- quote linebreak category is ambiguous depending on the language
   self.spaceTypes = { sp = true }
   self.wordTypes = { cm = true }
end

function nodemaker:dealWith (item)
   local char = item.text
   local cp = SU.codepoint(char)
   local thistype = chardata[cp] and chardata[cp].linebreak
   if self:isSpace(item.text) then
      self:makeToken()
      self:makeGlue(item)
   elseif self:isActiveNonBreakingSpace(item.text) then
      self:makeToken()
      self:makeNonBreakingSpace()
   elseif self:isBreaking(item.text) then
      self:addToken(char, item)
      self:makeToken()
      self:makePenalty(0)
   elseif self:isQuote(item.text) then
      self:addToken(char, item)
      self:makeToken()
   elseif self.lasttype and (thistype and thistype ~= self.lasttype and not self:isWord(thistype)) then
      self:addToken(char, item)
   else
      self:letterspace()
      self:addToken(char, item)
   end
   self.lasttype = thistype
end

function nodemaker:handleInitialGlue (items)
   local i = 1
   while i <= #items do
      local item = items[i]
      if self:isSpace(item.text) then
         self:makeGlue(item)
      else
         break
      end
      i = i + 1
   end
   return i, items
end

function nodemaker:letterspace ()
   if not self.language.settings:get("document.letterspaceglue") then
      return
   end
   if self.token then
      self:makeToken()
   end
   if self.lastnode and self.lastnode ~= "glue" then
      local w = self.language.settings:get("document.letterspaceglue").width
      SU.debug("tokenizer", "Letter space glue:", w)
      coroutine.yield(SILE.types.node.kern({ width = w }))
      self.lastnode = "glue"
      self.lasttype = "sp"
   end
end

function nodemaker.isICUBreakHere (_, chunks, item)
   return chunks[1] and (item.index >= chunks[1].index)
end

function nodemaker:handleICUBreak (chunks, item)
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

function nodemaker:handleWordBreak (item)
   self:makeToken()
   if self:isSpace(item.text) then
      -- Spacing word break
      self:makeGlue(item)
   elseif self:isActiveNonBreakingSpace(item.text) then
      -- Non-breaking space word break
      self:makeNonBreakingSpace()
   else
      -- a word break which isn't a space
      self:addToken(item.text, item)
   end
end

function nodemaker:handleLineBreak (item, subtype)
   -- Because we are in charge of paragraphing, we
   -- will override space-type line breaks, and treat
   -- them just as ordinary word spaces.
   if self:isSpace(item.text) or self:isActiveNonBreakingSpace(item.text) then
      self:handleWordBreak(item)
      return
   end
   -- But explicit line breaks we will turn into
   -- soft and hard breaks.
   self:makeToken()
   self:makePenalty(subtype == "soft" and 0 or -1000)
   local char = item.text
   self:addToken(char, item)
   local cp = SU.codepoint(char)
   self.lasttype = chardata[cp] and chardata[cp].linebreak
end

function nodemaker:iterator (items)
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

return nodemaker

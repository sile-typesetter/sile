local icu = require("justenoughicu")
local chardata = require("char-def")

SILE.nodeMakers.unicode.breakingTypes = { ba = true, zw = true }
SILE.nodeMakers.unicode.puctuationTypes = { po = true }
SILE.nodeMakers.unicode.quoteTypes = {} -- quote linebreak category is ambiguous depending on the language
SILE.nodeMakers.unicode.spaceTypes = { sp = true }
SILE.nodeMakers.unicode.wordTypes = { cm = true }

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
   elseif self:isActiveNonBreakingSpace(item.text) then
      -- Non-breaking space word break
      self:makeNonBreakingSpace()
   else
      -- a word break which isn't a space
      self:addToken(item.text, item)
   end
end

function SILE.nodeMakers.unicode:_handleWordBreakRepeatHyphen (item)
   -- According to some language rules, when a break occurs at an explicit hyphen,
   -- the hyphen gets repeated at the beginning of the new line
   if item.text == "-" then
      self:addToken(item.text, item)
      self:makeToken()
      if self.lastnode ~= "discretionary" then
         coroutine.yield(SILE.types.node.discretionary({
            postbreak = SILE.shaper:createNnodes("-", self.options),
         }))
         self.lastnode = "discretionary"
      end
   else
      SILE.nodeMakers.unicode.handleWordBreak(self, item)
   end
end

function SILE.nodeMakers.unicode:handleLineBreak (item, subtype)
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

function SILE.nodeMakers.unicode:_handleLineBreakRepeatHyphen (item, subtype)
   if self.lastnode == "discretionary" then
      -- Initial word boundary after a discretionary:
      -- Bypass it and just deal with the token.
      self:dealWith(item)
   else
      SILE.nodeMakers.unicode.handleLineBreak(self, item, subtype)
   end
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

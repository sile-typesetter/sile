local unicode = require("languages.unicode-nodemaker")

local nodemaker = pl.class(unicode)
nodemaker._name = "fr"

-- Unfortunately, there is nothing in the Unicode properties
-- database which distinguishes between high and low punctuation, etc.
-- But in a way that's precisely why we can't just rely on Unicode
-- for everything and need our language-specific typesetting
-- processors.
nodemaker.colonPunctuations = { ":" }
nodemaker.openingQuotes = { "«", "‹" }
nodemaker.closingQuotes = { "»", "›" }
-- There's catch below: the shaper may have already processed common ligatures (!!, ?!, !?)
-- as a single item...
nodemaker.highPunctuations = { ";", "!", "?", "!!", "?!", "!?" }
-- High punctuations have some (kern) space before them... except in some cases!
-- By the books, they have it "after a letter or digit", at least. After a closing
-- punctuation, too, seems usual.
-- Otherwise, one shall have no space inside e.g. (?), ?!, [!], …?, !!! etc.
-- As a simplification, we reverse the rule and define after which characters the space
-- shall not be added. This is by no mean perfect, I couldn't find an explicit list
-- of exceptions. French typography is a delicate beast.
nodemaker.spaceExceptions =
   { "!", "?", ":", ".", "…", "(", "[", "{", "<", "«", "‹", "“", "‘", "?!", "!!", "!?" }

-- TODO find a more ergonomic place to put obvious properties
-- (also in Catalan)
function nodemaker:_init (language, options)
   unicode._init(self, language, options)
   self.quoteTypes = { qu = true } -- split tokens at apostrophes etc.
end

local function getSpaceGlue (options, parameter)
   local sg
   if SILE.settings:get("languages.fr.debugspace") then
      sg = SILE.types.node.kern("5spc")
   else
      sg = SILE.settings:get(parameter)
   end
   -- Return the absolute (kern) length of the specified spacing parameter
   -- with a particular set of font options.
   -- As for SILE.shapers.base.measureSpace(), which has the same type of
   -- logic, caching this doesn't seem to have any significant speedup.
   SILE.settings:temporarily(function ()
      SILE.settings:set("font.size", options.size)
      SILE.settings:set("font.family", options.family)
      SILE.settings:set("font.filename", options.filename)
      sg = sg:absolute()
   end)
   -- Track a subtype on that kern:
   -- See automated italic correction at the typesetter level.
   sg.subtype = "punctspace"
   return sg
end

function nodemaker.isIn (_, set, text)
   for _, v in ipairs(set) do
      if v == text then
         return true
      end
   end
   return false
end

function nodemaker:isOpeningQuote (text)
   return self:isIn(self.openingQuotes, text)
end

function nodemaker:isClosingQuote (text)
   return self:isIn(self.closingQuotes, text)
end

function nodemaker:isColonPunctuation (text)
   return self:isIn(self.colonPunctuations, text)
end

function nodemaker:isHighPunctuation (text)
   return self:isIn(self.highPunctuations, text)
end

function nodemaker:isSpaceException (text)
   return self:isIn(self.spaceExceptions, text)
end

function nodemaker:isPrevSpaceException ()
   return self.i > 1 and self:isSpaceException(self.items[self.i - 1].text) or false
end

function nodemaker:makeUnbreakableSpace (parameter)
   self:makeToken()
   self.lastnode = "glue"
   coroutine.yield(getSpaceGlue(self.options, parameter))
end

function nodemaker:handleSpaceBefore (item)
   if self:isHighPunctuation(item.text) and not self:isPrevSpaceException() then
      self:makeUnbreakableSpace("languages.fr.thinspace")
      self:makeToken()
      self:addToken(item.text, item)
      return true
   end
   if self:isColonPunctuation(item.text) and not self:isPrevSpaceException() then
      self:makeUnbreakableSpace("languages.fr.colonspace")
      self:makeToken()
      self:addToken(item.text, item)
      return true
   end
   if self:isClosingQuote(item.text) then
      self:makeUnbreakableSpace("languages.fr.guillspace")
      self:makeToken()
      self:addToken(item.text, item)
      return true
   end
   return false
end

function nodemaker:handleSpaceAfter (item)
   if self:isOpeningQuote(item.text) then
      self:addToken(item.text, item)
      self:makeUnbreakableSpace("languages.fr.guillspace")
      self:makeToken()
      return true
   end
   return false
end

function nodemaker:mustRemove (i, items)
   -- Clear "manual" spaces we do not want, so that later we only have to
   -- insert the relevant kerns.
   local curr = items[i].text
   if self:isSpace(curr) or self:isNonBreakingSpace(curr) then
      if i < #items then
         local next = items[i + 1].text
         if
            self:isSpace(next)
            or self:isNonBreakingSpace(next)
            or self:isHighPunctuation(next)
            or self:isColonPunctuation(next)
            or self:isClosingQuote(next)
         then
            return true
         end
      end
      if i > 1 then
         local prev = items[i - 1].text
         if self:isOpeningQuote(prev) then
            return true
         end
      end
   end
   return false
end

-- overridden methods from parent class

function nodemaker:dealWith (item)
   if self:handleSpaceBefore(item) then
      return
   end
   if self:handleSpaceAfter(item) then
      return
   end
   unicode.dealWith(self, item)
end

function nodemaker:handleWordBreak (item)
   if self:handleSpaceBefore(item) then
      return
   end
   if self:handleSpaceAfter(item) then
      return
   end
   unicode.handleWordBreak(self, item)
end

function nodemaker:handleLineBreak (item, subtype)
   if self:isSpace(item.text) then
      self:handleWordBreak(item)
      return
   end
   if self:handleSpaceBefore(item) then
      return
   end
   if self:handleSpaceAfter(item) then
      return
   end

   unicode.handleLineBreak(self, item, subtype)
end

function nodemaker:iterator (items)
   -- We start by cleaning up the input once for all.
   local cleanItems = {}
   local removed = 0
   for k = 1, #items do
      if self:mustRemove(k, items) then
         -- the index is actually a character position in the byte stream.
         -- So we need to take its actual byte length into account.
         -- For instance, U+00A0 NBSP is 2 bytes long (0xC2 0xA0) in UTF-8.
         removed = removed + string.len(items[k].text)
      else
         -- index has changed due to removals
         items[k].index = items[k].index - removed
         table.insert(cleanItems, items[k])
      end
   end
   return unicode.iterator(self, cleanItems)
end

return nodemaker

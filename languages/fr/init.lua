--- French language rules
-- @submodule languages

local computeSpaces = function ()
   -- Computes:
   --  -  regular inter-word space,
   --  -  half inter-word fixed space,
   --  -  "guillemet space", as defined in LaTeX's babel-french which is based
   --     on Thierry Bouche's recommendations,
   --  These should be usual for France and Canada. The Swiss may prefer a thin
   --  space for guillemets, that's why we are having settings hereafter.
   local enlargement = SILE.settings:get("shaper.spaceenlargementfactor")
   local stretch = SILE.settings:get("shaper.spacestretchfactor")
   local shrink = SILE.settings:get("shaper.spaceshrinkfactor")
   return {
      colonspace = SILE.types.length(enlargement .. "spc plus " .. stretch .. "spc minus " .. shrink .. "spc"),
      thinspace = SILE.types.length((0.5 * enlargement) .. "spc"),
      guillspace = SILE.types.length(
         (0.8 * enlargement) .. "spc plus " .. (0.3 * stretch) .. "spc minus " .. (0.8 * shrink) .. "spc"
      ),
   }
end

local spaces = computeSpaces()
-- NOTE: We are only doing it at load time. We don't expect the shaper settings to be often
-- changed arbitrarily _after_ having selected a language...

SILE.settings:declare({
   parameter = "languages.fr.colonspace",
   type = "kern",
   default = SILE.types.node.kern(spaces.colonspace),
   help = "The amount of space before a colon, theoretically a non-breakable, shrinkable, stretchable inter-word space",
})

SILE.settings:declare({
   parameter = "languages.fr.thinspace",
   type = "kern",
   default = SILE.types.node.kern(spaces.thinspace),
   help = "The amount of space before high punctuations, theoretically a fixed, non-breakable space, around half the inter-word space",
})

SILE.settings:declare({
   parameter = "languages.fr.guillspace",
   type = "kern",
   default = SILE.types.node.kern(spaces.guillspace),
   help = "The amount of space applying to guillemets, theoretically smaller than a non-breakable inter-word space, with reduced stretchability",
})

SILE.settings:declare({
   parameter = "languages.fr.debugspace",
   type = "boolean",
   default = false,
   help = "If switched to true, uses large spaces instead of the regular punctuation ones",
})

local getSpaceGlue = function (options, parameter)
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

SILE.nodeMakers.fr = pl.class(SILE.nodeMakers.unicode)

-- Unfortunately, there is nothing in the Unicode properties
-- database which distinguishes between high and low punctuation, etc.
-- But in a way that's precisely why we can't just rely on Unicode
-- for everything and need our language-specific typesetting
-- processors.
SILE.nodeMakers.fr.colonPunctuations = { ":" }
SILE.nodeMakers.fr.openingQuotes = { "«", "‹" }
SILE.nodeMakers.fr.closingQuotes = { "»", "›" }
-- There's catch below: the shaper may have already processed common ligatures (!!, ?!, !?)
-- as a single item...
SILE.nodeMakers.fr.highPunctuations = { ";", "!", "?", "!!", "?!", "!?" }
-- High punctuations have some (kern) space before them... except in some cases!
-- By the books, they have it "after a letter or digit", at least. After a closing
-- punctuation, too, seems usual.
-- Otherwise, one shall have no space inside e.g. (?), ?!, [!], …?, !!! etc.
-- As a simplification, we reverse the rule and define after which characters the space
-- shall not be added. This is by no mean perfect, I couldn't find an explicit list
-- of exceptions. French typography is a delicate beast.
SILE.nodeMakers.fr.spaceExceptions =
   { "!", "?", ":", ".", "…", "(", "[", "{", "<", "«", "‹", "“", "‘", "?!", "!!", "!?" }

-- overridden properties from parent class
SILE.nodeMakers.fr.quoteTypes = { qu = true } -- split tokens at apostrophes &c.

-- methods defined in this class

function SILE.nodeMakers.fr:isIn (set, text)
   for _, v in ipairs(set) do
      if v == text then
         return true
      end
   end
   return false
end

function SILE.nodeMakers.fr:isOpeningQuote (text)
   return self:isIn(self.openingQuotes, text)
end

function SILE.nodeMakers.fr:isClosingQuote (text)
   return self:isIn(self.closingQuotes, text)
end

function SILE.nodeMakers.fr:isColonPunctuation (text)
   return self:isIn(self.colonPunctuations, text)
end

function SILE.nodeMakers.fr:isHighPunctuation (text)
   return self:isIn(self.highPunctuations, text)
end

function SILE.nodeMakers.fr:isSpaceException (text)
   return self:isIn(self.spaceExceptions, text)
end

function SILE.nodeMakers.fr:isPrevSpaceException ()
   return self.i > 1 and self:isSpaceException(self.items[self.i - 1].text) or false
end

function SILE.nodeMakers.fr:makeUnbreakableSpace (parameter)
   self:makeToken()
   self.lastnode = "glue"
   coroutine.yield(getSpaceGlue(self.options, parameter))
end

function SILE.nodeMakers.fr:handleSpaceBefore (item)
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

function SILE.nodeMakers.fr:handleSpaceAfter (item)
   if self:isOpeningQuote(item.text) then
      self:addToken(item.text, item)
      self:makeUnbreakableSpace("languages.fr.guillspace")
      self:makeToken()
      return true
   end
   return false
end

function SILE.nodeMakers.fr:mustRemove (i, items)
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

function SILE.nodeMakers.fr:dealWith (item)
   if self:handleSpaceBefore(item) then
      return
   end
   if self:handleSpaceAfter(item) then
      return
   end
   self._base.dealWith(self, item)
end

function SILE.nodeMakers.fr:handleWordBreak (item)
   if self:handleSpaceBefore(item) then
      return
   end
   if self:handleSpaceAfter(item) then
      return
   end
   self._base.handleWordBreak(self, item)
end

function SILE.nodeMakers.fr:handleLineBreak (item, subtype)
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

   self._base.handleLineBreak(self, item, subtype)
end

function SILE.nodeMakers.fr:iterator (items)
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
   return self._base.iterator(self, cleanItems)
end

local hyphens = require("languages.fr.hyphens-tex")
SILE.hyphenator.languages["fr"] = hyphens

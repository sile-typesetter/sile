local chardata = require("char-def")

local nodemaker = pl.class()
nodemaker.type = "nodemaker"
nodemaker._name = "base"

-- To be set on instantiation per language specifications
nodemaker.breakingTypes = {}
nodemaker.puctuationTypes = {}
nodemaker.quoteTypes = {}
nodemaker.spaceTypes = {}
nodemaker.wordTypes = {}

function nodemaker:_init (language, options)
   self.language = language
   self._name = language._name
   self.contents = {}
   self.options = options
   self.token = ""
   self.lastnode = false
   self.lasttype = false
end

function nodemaker:makeToken ()
   if #self.contents > 0 then
      coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
      SU.debug("tokenizer", "Token:", self.token)
      self.contents = {}
      self.token = ""
      self.lastnode = "nnode"
   end
end

function nodemaker:addToken (char, item)
   self.token = self.token .. char
   table.insert(self.contents, item)
end

function nodemaker:makeGlue (item)
   if self.language.settings:get("typesetter.obeyspaces") or self.lastnode ~= "glue" then
      SU.debug("tokenizer", "Space node")
      coroutine.yield(SILE.shaper:makeSpaceNode(self.options, item))
   end
   self.lastnode = "glue"
   self.lasttype = "sp"
end

function nodemaker:makePenalty (p)
   if self.lastnode ~= "penalty" and self.lastnode ~= "glue" then
      coroutine.yield(SILE.types.node.penalty({ penalty = p or 0 }))
   end
   self.lastnode = "penalty"
end

function nodemaker:makeNonBreakingSpace ()
   -- Unicode Line Breaking Algorithm (UAX 14) specifies that U+00A0
   -- (NO-BREAK SPACE) is expanded or compressed like a normal space.
   coroutine.yield(SILE.types.node.kern(SILE.shaper:measureSpace(self.options)))
   self.lastnode = "glue"
   self.lasttype = "sp"
end

function nodemaker.iterator (_, _)
   SU.error("Abstract function nodemaker:iterator called", true)
end

function nodemaker.charData (_, char)
   local cp = SU.codepoint(char)
   if not chardata[cp] then
      return {}
   end
   return chardata[cp]
end

function nodemaker:isActiveNonBreakingSpace (char)
   return self:isNonBreakingSpace(char) and not self.language.settings:get("languages.fixedNbsp")
end

function nodemaker:isBreaking (char)
   return self.breakingTypes[self:charData(char).linebreak]
end

function nodemaker:isNonBreakingSpace (char)
   local c = self:charData(char)
   return c.contextname and c.contextname == "nobreakspace"
end

function nodemaker:isPunctuation (char)
   return self.puctuationTypes[self:charData(char).category]
end

function nodemaker:isSpace (char)
   return self.spaceTypes[self:charData(char).linebreak]
end

function nodemaker:isQuote (char)
   return self.quoteTypes[self:charData(char).linebreak]
end

function nodemaker:isWord (char)
   return self.wordTypes[self:charData(char).linebreak]
end

return nodemaker

nodeMaker = pl.class()
nodeMaker._name = "base"

function nodeMaker:_init (name, options)
   self._name = name
   self.contents = {}
   self.options = options
   self.token = ""
   self.lastnode = false
   self.lasttype = false
end

function nodeMaker:makeToken ()
   if #self.contents > 0 then
      coroutine.yield(SILE.shaper:formNnode(self.contents, self.token, self.options))
      SU.debug("tokenizer", "Token:", self.token)
      self.contents = {}
      self.token = ""
      self.lastnode = "nnode"
   end
end

function nodeMaker:addToken (char, item)
   self.token = self.token .. char
   table.insert(self.contents, item)
end

function nodeMaker:makeGlue (item)
   if SILE.settings:get("typesetter.obeyspaces") or self.lastnode ~= "glue" then
      SU.debug("tokenizer", "Space node")
      coroutine.yield(SILE.shaper:makeSpaceNode(self.options, item))
   end
   self.lastnode = "glue"
   self.lasttype = "sp"
end

function nodeMaker:makePenalty (p)
   if self.lastnode ~= "penalty" and self.lastnode ~= "glue" then
      coroutine.yield(SILE.types.node.penalty({ penalty = p or 0 }))
   end
   self.lastnode = "penalty"
end

function nodeMaker:makeNonBreakingSpace ()
   -- Unicode Line Breaking Algorithm (UAX 14) specifies that U+00A0
   -- (NO-BREAK SPACE) is expanded or compressed like a normal space.
   coroutine.yield(SILE.types.node.kern(SILE.shaper:measureSpace(self.options)))
   self.lastnode = "glue"
   self.lasttype = "sp"
end

function nodeMaker.iterator (_, _)
   SU.error("Abstract function nodemaker:iterator called", true)
end

function nodeMaker.charData (_, char)
   local cp = SU.codepoint(char)
   if not chardata[cp] then
      return {}
   end
   return chardata[cp]
end

function nodeMaker:isActiveNonBreakingSpace (char)
   return self:isNonBreakingSpace(char) and not SILE.settings:get("languages.fixedNbsp")
end

function nodeMaker:isBreaking (char)
   return self.breakingTypes[self:charData(char).linebreak]
end

function nodeMaker:isNonBreakingSpace (char)
   local c = self:charData(char)
   return c.contextname and c.contextname == "nobreakspace"
end

function nodeMaker:isPunctuation (char)
   return self.puctuationTypes[self:charData(char).category]
end

function nodeMaker:isSpace (char)
   return self.spaceTypes[self:charData(char).linebreak]
end

function nodeMaker:isQuote (char)
   return self.quoteTypes[self:charData(char).linebreak]
end

function nodeMaker:isWord (char)
   return self.wordTypes[self:charData(char).linebreak]
end

return nodeMaker



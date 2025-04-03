local unicode = require("languages.unicode-nodemaker")

local nodeMaker = pl.class(unicode)
nodeMaker._name = "repeat-hyphen"

function nodeMaker:handleWordBreak (item)
   -- According to some language rules, when a break occurs at an explicit hyphen,
   -- the hyphen gets repeated at the beginning of the new line
   if item.text == "-" then
      self:addToken(item.text, item)
      self:makeToken()
      if self.lastnode ~= "discretionary" then
         local postbreak = SILE.shaper:createNnodes("-", self.options)
         coroutine.yield(SILE.types.node.discretionary({
            postbreak = postbreak,
         }))
         self.lastnode = "discretionary"
      end
   else
      unicode.handleWordBreak(self, item)
   end
end

function nodeMaker:handleLineBreak (item, subtype)
   if self.lastnode == "discretionary" then
      -- Initial word boundary after a discretionary:
      -- Bypass it and just deal with the token.
      self:dealWith(item)
   else
      unicode.handleLineBreak(self, item, subtype)
   end
end

return nodeMaker

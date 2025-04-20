local unicode = require("languages.unicode-nodemaker")

local nodemaker = pl.class(unicode)
nodemaker._name = "grc"

function nodemaker:iterator (items)
   return coroutine.wrap(function ()
      for i = 1, #items do
         self:addToken(items[i].text, items[i])
         self:makeToken()
         self:makePenalty()
         coroutine.yield(SILE.types.node.glue("0pt plus 2pt"))
      end
   end)
end

return nodemaker

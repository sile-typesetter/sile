local unicode = require("languages.unicode-nodemaker")

local nodeMaker = pl.class(unicode)
nodeMaker._name = "grc"

function nodeMaker:iterator (items)
   return coroutine.wrap(function ()
      for i = 1, #items do
         self:addToken(items[i].text, items[i])
         self:makeToken()
         self:makePenalty()
         coroutine.yield(SILE.types.node.glue("0pt plus 2pt"))
      end
   end)
end

return nodeMaker

require("char-def")
local chardata  = characters.data

SILE.tokenizers.unicode = function(text)
  local chunks = SU.splitUtf8(text)
  return coroutine.wrap(function()
    local tmp = {}
    for i = 1,#chunks do 
      local cp = SU.codepoint(chunks[i])
      if chardata[cp] and chardata[cp].linebreak == "sp" then
        coroutine.yield({ string = table.concat(tmp, "") })
        tmp = {}
        coroutine.yield({ separator = chunks[i]})
      elseif chardata[cp] and (chardata[cp].linebreak == "ba" or  chardata[cp].linebreak == "zw") then
        tmp[#tmp+1] = chunks[i]
        coroutine.yield({ string = table.concat(tmp, "") })
        tmp = {}
        coroutine.yield({ node = SILE.nodefactory.newPenalty({ penalty = 0 }) })
      else
        tmp[#tmp+1] = chunks[i]
      end
    end
    coroutine.yield({ string = table.concat(tmp, "") })
  end)
end    

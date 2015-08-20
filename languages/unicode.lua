require("char-def")
local chardata  = characters.data

pcall( function () icu = require("justenoughicu") end)
if icu then
  SILE.tokenizers.unicode = function(text)
    local chunks = {icu.breakpoints(text)}
    return coroutine.wrap(function()
      for i = 2,(#chunks) do local chunk = chunks[i]
        if chunk.token:match("^%s+$") then
          coroutine.yield({ separator = chunk.token })
        elseif chunk.type == "line" then
          if #(chunk.token) > 0 then coroutine.yield({ string = chunk.token }) end
          coroutine.yield({ node = SILE.nodefactory.newPenalty({
            penalty = (chunk.subtype == "soft" and 0 or -1000) })
          })
        else
          coroutine.yield({ string = chunk.token })
        end
      end
    end)
  end
else
  SILE.tokenizers.unicode = function(text)
    local chunks = SU.splitUtf8(text)
    return coroutine.wrap(function()
      local tmp = {}
      local lasttype
      for i = 1,#chunks do
        local cp = SU.codepoint(chunks[i])
        local thistype = chardata[cp].linebreak
        if chardata[cp] and thistype == "sp" then
          if #tmp>0 then coroutine.yield({ string = table.concat(tmp, "") }) end
          tmp = {}
          coroutine.yield({ separator = chunks[i]})
        elseif chardata[cp] and (thistype == "ba" or  thistype == "zw") then
          tmp[#tmp+1] = chunks[i]
          coroutine.yield({ string = table.concat(tmp, "") })
          tmp = {}
          coroutine.yield({ node = SILE.nodefactory.newPenalty({ penalty = 0 }) })
        elseif lasttype and (thistype ~= lasttype and thistype ~= "cm") then
          if #tmp>0 then coroutine.yield({ string = table.concat(tmp, "") }) end
          tmp = {}
          tmp[#tmp+1] = chunks[i]
        else
          tmp[#tmp+1] = chunks[i]
        end
        if thistype ~= "cm" then lasttype = chardata[cp].linebreak end
      end
      coroutine.yield({ string = table.concat(tmp, "") })
    end)
  end
end
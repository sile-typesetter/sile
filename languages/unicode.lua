require("char-def")
local chardata  = characters.data

-- pcall( function () icu = require("justenoughicu") end)
if icu then
  SILE.tokenizers.unicode = function(text)
    local chunks = {icu.breakpoints(text)}
    return coroutine.wrap(function()
      for i = 1,#chunks do local chunk = chunks[i]
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
        if chardata[cp] and chardata[cp].linebreak == "sp" then
          coroutine.yield({ string = table.concat(tmp, "") })
          tmp = {}
          coroutine.yield({ separator = chunks[i]})
        elseif chardata[cp] and (chardata[cp].linebreak == "ba" or  chardata[cp].linebreak == "zw") then
          tmp[#tmp+1] = chunks[i]
          coroutine.yield({ string = table.concat(tmp, "") })
          tmp = {}
          coroutine.yield({ node = SILE.nodefactory.newPenalty({ penalty = 0 }) })
        elseif lasttype and chardata[cp].linebreak ~= lasttype then
          coroutine.yield({ string = table.concat(tmp, "") })
          tmp = {}
          tmp[#tmp+1] = chunks[i]
        else
          tmp[#tmp+1] = chunks[i]
        end
        lasttype = chardata[cp].linebreak
      end
      coroutine.yield({ string = table.concat(tmp, "") })
    end)
  end
end
require("char-def")
local chardata  = characters.data

SILE.nodeMakers.unicode = function(items,text,options)
  local contents = {}
  local token = ""
  local lastnode

  local shipToken = function ()
    if #contents>0 then
      coroutine.yield(SILE.shaper:formNnode(contents, token, options))
      contents = {} ; token = "" ; lastnode = "nnode"
    end
  end
  local addToken = function (char,item)
    token = token .. char
    contents[#contents+1] = item
  end

  return coroutine.wrap(function()
    for i = 1,#items do item = items[i]
      local char = items[i].text
      local cp = SU.codepoint(char)
      local thistype = chardata[cp] and chardata[cp].linebreak
      if chardata[cp] and thistype == "sp" then
        shipToken()
        if lastnode ~= "glue" then
          coroutine.yield(SILE.shaper:makeSpaceNode(options))
        end
        lastnode = "glue"
      elseif chardata[cp] and (thistype == "ba" or  thistype == "zw") then
        addToken(char,item)
        shipToken()
        coroutine.yield( SILE.nodefactory.newPenalty({ penalty = 0 }) )
        lastnode = "penalty"
      elseif lasttype and (thistype ~= lasttype and thistype ~= "cm") then
        shipToken()
        addToken(char,item)
      else
        addToken(char,item)
      end
      if thistype ~= "cm" then lasttype = chardata[cp] and chardata[cp].linebreak end
    end
    shipToken()
  end)
end

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
end
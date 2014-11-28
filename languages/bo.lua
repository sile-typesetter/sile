
local tseg = "\224\188\139"
local linebreak = SILE.nodefactory.newPenalty({penalty = 0})

SILE.tokenizers.bo = function(string)
  return coroutine.wrap(function()
    for token in SU.gtoke(string, '%s+') do
      if token.separator then coroutine.yield(token)
      else -- further break down
        local s = token.string
        for token in SU.gtoke(s, tseg) do
          if token.separator then
            coroutine.yield({string = tseg})
            coroutine.yield({node = linebreak})
          else coroutine.yield(token) end
        end
      end
    end
  end)
end

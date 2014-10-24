SILE.tokenizers.ja = function(string)
  return coroutine.wrap(function()
    local space = SILE.settings.get("shaper.spacepattern")
    for uchar in string.gmatch(string, "([%z\1-\127\194-\244][\128-\191]*)") do
      if string.match(uchar, space) then
        coroutine.yield({separator = uchar})
      else
        coroutine.yield({ string = uchar })
        coroutine.yield({node = SILE.nodefactory.zeroGlue })
      end
    end
  end)
end
print("OK")
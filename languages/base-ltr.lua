return {
  tokenizer = function (text)
    -- NO, THIS IS WRONG. DON'T DO THIS.
    local f = {}
    for token in SILE.tokenizers.default(text) do
      f[#f+1] = token
    end
    local i = #f
    return coroutine.wrap(function()
      while i > 1 do
        coroutine.yield(f[i])
        i = i - 1
      end
    end)
  end
}
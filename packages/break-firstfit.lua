-- Sometimes you just want a simple first-fit paragraph breaking
-- algorithm, especially when you're dealing with vertical
-- typesetting. Oh, and it's really fast too.

local firstfit = function (typesetter, nl, breakWidth)
  local breaks = {}
  local length = SILE.length.new()
  for i = 1,#nl do local n = nl[i]
    if n:isBox() then
      SU.debug("break", n .. " ".. n:lineContribution())
      length = length + n:lineContribution()
      SU.debug("break", " Length now ".. length.. " breakwidth ".. breakWidth)
    end
    if not n:isBox() or n.isHangable then
      SU.debug("break", n )
      if n:isGlue() then
        length = length + n.width.length
      end
      SU.debug("break", " Length now ".. length.. " breakwidth ".. breakWidth)
      -- Can we break?
      if length.length >= breakWidth then
        SU.debug("break", "Breaking!")
        breaks[#breaks+1] = { position = i, width = breakWidth}
        length = SILE.length.new()
      end
    end
  end
  breaks[#breaks+1] = { position = #nl, width = breakWidth}
  return typesetter:breakpointsToLines(breaks)
end

return firstfit

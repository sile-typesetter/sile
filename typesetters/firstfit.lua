local base = require("typesetters.base")

local typesetter = pl.class(base)
typesetter._name = "firstfit"

function typesetter:breakIntoLines (nl, breakWidth)
  local breaks = {}
  local length = SILE.types.length()
  for i = 1,#nl do local n = nl[i]
    if n.is_box then
      SU.debug("break", n, function () return n:lineContribution() end)
      length = length + n:lineContribution()
      SU.debug("break", " Length now ", length, "breakwidth", breakWidth)
    end
    if not n.is_box or n.isHangable then
      SU.debug("break", n )
      if n.is_glue then
        length = length + n.width:absolute()
      end
      SU.debug("break", " Length now ", length, " breakwidth ", breakWidth)
      -- Can we break?
      if length:tonumber() >= breakWidth:tonumber() then
        SU.debug("break", "Breaking!")
        breaks[#breaks+1] = { position = i, width = breakWidth}
        length = SILE.types.length()
      end
    end
  end
  breaks[#breaks+1] = { position = #nl, width = breakWidth}
  return self:breakpointsToLines(breaks)
end

return typesetter

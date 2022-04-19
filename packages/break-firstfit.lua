-- Sometimes you just want a simple first-fit paragraph breaking
-- algorithm, especially when you're dealing with vertical
-- typesetting. Oh, and it's really fast too.

local firstfit = function (typesetter, nl, breakWidth)
  local breaks = {}
  local length = SILE.length()
  for i = 1,#nl do local n = nl[i]
    if n.is_box then
      SU.debug("break", n .. " " .. n:lineContribution())
      length = length + n:lineContribution()
      SU.debug("break", " Length now " .. length.. " breakwidth ".. breakWidth)
    end
    if not n.is_box or n.isHangable then
      SU.debug("break", n )
      if n.is_glue then
        length = length + n.width:absolute()
      end
      SU.debug("break", " Length now " .. length .. " breakwidth " .. breakWidth)
      -- Can we break?
      if length:tonumber() >= breakWidth:tonumber() then
        SU.debug("break", "Breaking!")
        breaks[#breaks+1] = { position = i, width = breakWidth}
        length = SILE.length()
      end
    end
  end
  breaks[#breaks+1] = { position = #nl, width = breakWidth}
  return typesetter:breakpointsToLines(breaks)
end

return {
  init = function () end,
  exports = {
    breakIntoLines = firstfit
  },
  documentation = [[\begin{document}
SILE’s normal page breaking algorithm is based on the Knuth-Plass “best-fit”
method, which tests a variety of possible paragraph constructions before
deciding on the visually optimal one. That guarantees great results for texts
which require full justification, but some languages don’t need that degree
of complexity. In particular, Japanese is traditionally typeset on a grid
system with characters being essentially monospaced. You don’t need to do
anything clever to break that into lines: just stop when you get to the end
of the line and start a new one (the “first-fit” method). This package implements
the first-fit technique. It’s currently designed to be used by other packages
so it doesn’t currently provide any user-facing commands.
\end{document}]]
}

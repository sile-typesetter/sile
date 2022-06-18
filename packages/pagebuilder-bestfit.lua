local MAX_PAGES = 5

local function init (_, _)

  SILE.typesetter.buildPage = function (self, independent)
    -- Find last penalty
    local q = self.state.outputQueue
    local lastpenalty = -1
    local cHeight = SILE.length()
    for j = #q,1,-1 do
      if q[j].is_penalty and lastpenalty == -1 then
        lastpenalty = q[j].penalty
      end
      cHeight = cHeight + q[j].height
    end
    if not(cHeight > self.frame:height() * MAX_PAGES) and not(independent) and lastpenalty > -10000 then return false end
    SU.debug("pagebuilder", "Finally running pagebuilder")
    repeat
      q = self.state.outputQueue
      local breaks = SILE.linebreak:doBreak( q, self.frame:height(), true)
      --Height is variable! therefore only the first break is believable
      local point = breaks[1]
      if point.position == 0 then return false end
      local linestart = 1
      local slice = {}
      local newslice = {}
      for j = linestart, #self.state.outputQueue do
        if j <= point.position then slice[#slice+1] = q[j]  else newslice[#newslice+1] = q[j] end
      end
      self:setVerticalGlue(slice, self.frame:height())
      self:outputLinesToPage(slice)
      self.state.outputQueue = newslice
      if #(self.state.outputQueue) == 0 then return false end

      self:initNextFrame() -- This causes a tail call if there is more stuff waiting
      -- If not, we keep going if we are being asked to ship out a page now now now.
    until lastpenalty > -10000
    return false -- because we have already dealt with initializing the next frame
  end

end

return {
  init = init,
  documentation = [[
\begin{document}
Many of SILE’s core algorithms are borrowed from TeX, including the page builder.
While TeX’s \em{paragraph} builder uses the “best-fit” algorithm, trying
multiple different paragraphing options to find the best justification, the page
builder takes a more simple “first-fit” approach, shipping out a page as soon as
the page target is met. This experimental package uses the \em{paragraph}
builder to build \em{pages}, applying the best-fit method to the set of vertical
boxes and the vertical target instead of a set of horizontal boxes and a
horizontal target.
\end{document}
]]
}

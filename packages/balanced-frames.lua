local BALANCE_PENALTY = -17777

local function init (_, _)

  SILE.typesetter.buildPage = function (self, independent)
    local frame = self.frame
    if not (frame.balanced == true) then return SILE.defaultTypesetter.buildPage(self, independent) end

    local colCount = 0
    local target = SILE.length()
    while frame and frame.balanced == true do
      target = target + frame:height()
      colCount = colCount + 1
      if frame.next then frame = SILE.getFrame(frame.next) else break end
    end

    -- Really, try and avoid doing anything, where possible.
    if colCount == 1 then return SILE.defaultTypesetter.buildPage(self, independent) end
    -- If the total amount of stuff on the output list is greater then the total
    -- of frame space on the page, and there are no magic requests to balance the
    -- columns, then we have a full page. Just send it out normally.
    local q = self.state.outputQueue
    local totalHeight = SILE.length()
    local mustBalance = 0
    for i = 1, #q do
      totalHeight = totalHeight + q[i].height + q[i].depth
      if q[i].is_penalty and q[i].penalty <= BALANCE_PENALTY then
        mustBalance = i
        break
      end
    end
    if totalHeight.length > target.length and mustBalance == 0 and not independent then
      return SILE.defaultTypesetter.buildPage(self, independent)
    end

    -- Have we been explicitly asked to find a pagebreak at this point?
    -- If not, don't bother
    if mustBalance == 0 and not independent then return false end
    SU.debug("balancer", "Balancing " .. tostring(totalHeight) .. " of material over " .. colCount .. " frames (total of ".. tostring(target) .. ")")
    SU.debug("balancer", "Must balance because mustBalance=" .. mustBalance .. " and independent = " .. tostring(independent))
    -- OK. Now we have to balance the frames. We are going to cheat and
    -- adjust the height of each frame to be an appropriate fraction of
    -- the content height
    frame = self.frame
    SU.debug("balancer", "Each column is now "..(totalHeight.length / colCount))
    while frame and frame.balanced == true do
      frame:relax("bottom")
      frame:constrain("height", totalHeight.length / colCount)
      if frame.next then frame = SILE.getFrame(frame.next) else break end
    end
    self.state.lastPenalty = 0
    local oldPageBuilder = SILE.pagebuilder
    SILE.pagebuilder = require("core.pagebuilder")()
    while self.frame and self.frame.balanced do
      SILE.defaultTypesetter.buildPage(self, true)
      if self.frame.next and SILE.getFrame(self.frame.next).balanced == true then
        self:initFrame(SILE.getFrame(self.frame.next))
        self:runHooks("newframe")
      else
        break -- Break early, because when we return
      end
    end
    SILE.pagebuilder = oldPageBuilder
    SU.debug("balancer", "Finished this balance, frame id is now " .. tostring(self.frame))
    -- SILE.typesetter:debugState()
    -- We're done.
    return true
  end

end

local function registerCommands (_)

  SILE.registerCommand("balancecolumns", function (_, _)
    SILE.typesetter:leaveHmode()
    SILE.call("penalty", { penalty = BALANCE_PENALTY })
  end)

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation=[[\begin{document}
This package attempts to ensure that the main content frames on a
page are balanced; that is, that they have the same height. In your
frame definitions for the columns, you will need to ensure that they
have the parameter \autodoc:parameter{balanced} set to a true value. See the example
in \code{tests/balanced.sil}.

The current algorithm does not work particularly well, and a better solution
to the column problem is being developed.
\end{document}]]
}

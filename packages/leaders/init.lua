local base = require("packages.base")

local package = pl.class(base)
package._name = "leaders"

--
-- Leaders package
--

local widthToFrameEdge = function (frame)
  local w
  if frame:writingDirection() == "LTR" then
    w = frame:right() - frame.state.cursorX
  elseif frame:writingDirection() == "RTL" then
    w = frame.state.cursorX - frame:left()
  elseif frame:writingDirection() == "TTB" then
    w = frame:bottom() - frame.state.cursorY
  elseif frame:writingDirection() == "BTT" then
    w = frame.state.cursorY - frame:top()
  else
    SU.error("Unknown writing direction")
  end
  return w
end

local leader = pl.class(SILE.nodefactory.glue)

function leader:outputYourself (typesetter, line)
  local outputWidth = SU.rationWidth(self.width, self.width, line.ratio):tonumber()
  local leaderWidth = self.value.width:tonumber()
  local ox = typesetter.frame.state.cursorX
  local oy = typesetter.frame.state.cursorY

  -- Implementation note:
  -- We want leaders on different lines to be aligned vertically in the frame,
  -- from its end edge (e.g. the right edge in LTR writing direction).

  -- Compute how many leaders we can fit from the current initial position.
  local fitWidth = widthToFrameEdge(typesetter.frame):tonumber()
  local maxRepetitions = math.floor(fitWidth / leaderWidth) -- round down!
  -- Compute how many leaders we have to skip after our final position.
  typesetter.frame:advanceWritingDirection(outputWidth)
  local skipWidth = widthToFrameEdge(typesetter.frame):tonumber()
  skipWidth = math.floor(skipWidth * 1e6) / 1e6 -- accept some rounding imprecision
  local skipRepetitions = math.ceil(skipWidth / leaderWidth) -- round up!

  local repetitions = maxRepetitions - skipRepetitions
  local remainder = fitWidth - maxRepetitions * leaderWidth
  SU.debug("leaders", "Leader repetitions: "..repetitions
    ..", skipped: "..skipRepetitions..", remainder: "..remainder.."pt")

  -- Return back to our start position
  typesetter.frame:advanceWritingDirection(-outputWidth)
  -- Handle the leader element repetitions
  if repetitions > 0 then
    typesetter.frame:advanceWritingDirection(remainder)
    for _ = 1, repetitions do
      if SU.debugging("leaders") then
        -- Draw some visible lines around leader repetitions.
        -- N.B. This might be wrong for other directions than LTR-TTB, but heh it's debug stuff.
        SILE.outputter:drawRule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-leaderWidth, leaderWidth-0.3, 0.3)
        SILE.outputter:drawRule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-leaderWidth, 0.3, leaderWidth-0.3)
      end

      self.value:outputYourself(typesetter, line)
    end

    if SU.debugging("leaders") then
      -- Draw some visible lines around skipped leader repetitions.
      -- N.B. This might be wrong for other directions than LTR-TTB, but it's debug stuff again.
      for _ = 0, skipRepetitions-1 do
        SILE.outputter:drawRule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY, leaderWidth, 0.3)
        SILE.outputter:drawRule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-leaderWidth, 0.3, leaderWidth)
        typesetter.frame:advanceWritingDirection(leaderWidth)
      end
    end
  end
  -- Return to our start (saved) position and move to the full leaders width.
  -- (So we are sure to safely get the correct width, whathever we did above
  -- with the remainder space and the leader repetitions).
  typesetter.frame.state.cursorX = ox
  typesetter.frame.state.cursorY = oy
  typesetter.frame:advanceWritingDirection(outputWidth)

end

function package:registerCommands ()

  self:registerCommand("leaders", function(options, content)
    local width = options.width and SU.cast("glue", options.width) or SILE.nodefactory.hfillglue()
    SILE.call("hbox", {}, content)
    local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
    SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
    local l = leader({ width = width, value = hbox })
    SILE.typesetter:pushExplicitGlue(l)
  end)

  self:registerCommand("dotfill", function(_, _)
    -- Implementation note:
    -- The "usual" space between dots in "modern days" is 0.5em (cf. "points
    -- conducteurs" in Frey & Bouchez, 1857), evenly distributed around the dot,
    -- though in older times it was sometimes up to 1em and could be distributed
    -- differently. Anyhow, it is also the approach taken by LaTeX, with a
    -- \@dotsep space of 4.5mu (where 18mu = 1em, so indeed leading to 0.25em).
    SILE.call("leaders", { width = SILE.nodefactory.hfillglue() }, function()
      SILE.call("kern", { width = SILE.length("0.25em") })
      SILE.typesetter:typeset(".")
      SILE.call("kern", {width = SILE.length("0.25em") })
    end)
  end)

end

package.documentation = [[
\begin{document}
The \autodoc:package{leaders} package allows you to create repeating patterns which fill a given space.
It provides the \autodoc:command{\dotfill} command, which does this:

\begin[type=autodoc:codeblock]{raw}
A\dotfill{}B
\end{raw}

\begin{examplefont}
A\dotfill{}B\par
\end{examplefont}

It also provides the \autodoc:command{\leaders[width=<dimension>]{<content>}} command which allow you to define your own leaders.
For example:

\begin[type=autodoc:codeblock]{raw}
A\leaders[width=40pt]{/\\}B
\end{raw}

\begin{examplefont}
A\leaders[width=40pt]{/\\}B\par
\end{examplefont}

If the width is omitted, the leaders extend as much as possible (as a \autodoc:command{\dotfill} or \autodoc:command{\hfill}).

Leader patterns are always vertically aligned, respectively to the end edge of the frame they appear in, for a given font.
It implies that the number of repeated patterns and their positions do not only depend on the available space, but also on the alignment constraint and the active font.
\end{document}
]]

return package
